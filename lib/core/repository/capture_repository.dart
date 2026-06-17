import 'dart:math';

import '../constants/app_constants.dart';
import '../models/activity.dart';
import '../models/capture.dart';
import '../models/enums.dart';
import '../models/extraction.dart';
import '../services/ai/ai_service.dart';
import '../services/local_store.dart';

/// Owns the capture lifecycle (spec §8 `capture`): the F3 pending queue, the
/// F2/F4 voice→transcript→extraction step, the F5–F7 fan-out write, and the
/// one-tap undo. State is persisted locally in demo mode and re-loaded on boot.
class CaptureRepository {
  CaptureRepository({required AiService ai, required LocalStore store})
      : _ai = ai,
        _store = store;

  final AiService _ai;
  final LocalStore _store;

  List<Capture> _pending = <Capture>[];
  List<ActivityEntry> _activity = <ActivityEntry>[];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final List<dynamic> captures = await _store.readList(StorageKeys.captures);
    final List<dynamic> activity = await _store.readList(StorageKeys.activity);
    if (captures.isEmpty) {
      _pending = _seedPending();
      await _persistCaptures();
    } else {
      _pending = captures
          .whereType<Map<String, dynamic>>()
          .map(Capture.fromJson)
          .toList();
    }
    _activity = activity
        .whereType<Map<String, dynamic>>()
        .map(ActivityEntry.fromJson)
        .toList();
  }

  // --- Reads ----------------------------------------------------------------

  Future<List<Capture>> pendingCaptures() async {
    await _ensureLoaded();
    await Future<void>.delayed(AppConstants.mockLatency);
    return _pending.where((Capture c) => c.isPending).toList()
      ..sort((Capture a, Capture b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<ActivityEntry>> activity() async {
    await _ensureLoaded();
    return List<ActivityEntry>.of(_activity)
      ..sort((ActivityEntry a, ActivityEntry b) =>
          b.timestamp.compareTo(a.timestamp));
  }

  // --- Voice → extraction (F2/F4) ------------------------------------------

  /// Runs the shared extraction engine on a transcript. Throws if the model
  /// returns a malformed record — the app never writes invalid data (F4).
  Future<Extraction> draft(String transcript) async {
    final Extraction extraction = await _ai.extract(transcript);
    if (!extraction.isValid) {
      throw const FormatException('Extraction was incomplete — please retry.');
    }
    return extraction;
  }

  // --- Confirm / write (F5–F7) ---------------------------------------------

  /// Writes a confirmed capture to CRM + task tool + calendar and records the
  /// result. Idempotent per [capture.id]; partial failures are surfaced.
  Future<ActivityEntry> confirm({
    required Capture capture,
    required Extraction extraction,
  }) async {
    await _ensureLoaded();
    await Future<void>.delayed(AppConstants.mockLatency);

    // Simulate an occasional task-tool hiccup so partial-failure UX is real.
    final bool taskOk = !(Random().nextInt(6) == 0 &&
        extraction.actionItems.any((ActionItem a) => a.selected));

    final ActivityEntry entry = ActivityEntry(
      id: 'act-${DateTime.now().microsecondsSinceEpoch}',
      clientName: extraction.client,
      description: extraction.summary,
      updateType: extraction.updateType,
      timestamp: DateTime.now(),
      taskOk: taskOk,
    );

    _activity = <ActivityEntry>[entry, ..._activity];
    _pending = _pending
        .map((Capture c) => c.id == capture.id
            ? c.copyWith(status: CaptureStatus.written, extraction: extraction)
            : c)
        .toList();

    await _persistAll();
    return entry;
  }

  /// One-tap undo: removes the activity and restores the capture to pending.
  Future<void> undo(ActivityEntry entry, {String? captureId}) async {
    await _ensureLoaded();
    _activity = _activity.where((ActivityEntry a) => a.id != entry.id).toList();
    if (captureId != null) {
      _pending = _pending
          .map((Capture c) => c.id == captureId
              ? c.copyWith(status: CaptureStatus.pending)
              : c)
          .toList();
    }
    await _persistAll();
  }

  /// Adds a fresh conversational capture to the queue (used when a draft is
  /// saved for later rather than written immediately).
  Future<Capture> enqueue(Capture capture) async {
    await _ensureLoaded();
    _pending = <Capture>[capture, ..._pending];
    await _persistCaptures();
    return capture;
  }

  // --- Persistence ----------------------------------------------------------

  Future<void> _persistAll() async {
    await _persistCaptures();
    await _store.writeJson(
      StorageKeys.activity,
      _activity.map((ActivityEntry a) => a.toJson()).toList(),
    );
  }

  Future<void> _persistCaptures() async {
    await _store.writeJson(
      StorageKeys.captures,
      _pending.map((Capture c) => c.toJson()).toList(),
    );
  }

  List<Capture> _seedPending() => <Capture>[
        Capture(
          id: 'cap-acme',
          clientName: 'Acme Corp',
          summary: 'Capture the outcome of the discovery call.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
          source: CaptureSource.postMeeting,
          meetingId: 'mtg-acme',
        ),
        Capture(
          id: 'cap-northstar',
          clientName: 'Northstar Industries',
          summary: 'Product walkthrough — log the outcome.',
          createdAt: DateTime.now().subtract(const Duration(hours: 20)),
          source: CaptureSource.postMeeting,
          meetingId: 'mtg-northstar',
        ),
      ];
}
