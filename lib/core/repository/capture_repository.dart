import '../config/app_config.dart';
import '../constants/app_constants.dart';
import '../models/activity.dart';
import '../models/capture.dart';
import '../models/crm.dart';
import '../models/enums.dart';
import '../models/extraction.dart';
import '../services/ai/ai_service.dart';
import '../services/crm/leads_crm_service.dart';
import '../services/local_store.dart';
import '../services/tasks/trello_service.dart';

/// Owns the capture lifecycle (spec §8 `capture`): the F3 pending queue, the
/// F2/F4 voice→transcript→extraction step, the F5–F7 fan-out write, and the
/// one-tap undo. State is persisted locally in demo mode and re-loaded on boot.
class CaptureRepository {
  CaptureRepository({
    required AiService ai,
    required LocalStore store,
    required LeadsCrmService crm,
    required TrelloService trello,
  })  : _ai = ai,
        _store = store,
        _crm = crm,
        _trello = trello;

  final AiService _ai;
  final LocalStore _store;
  final LeadsCrmService _crm;
  final TrelloService _trello;

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

  /// Writes a confirmed capture and fans out (F5–F7). The user-reviewed
  /// [extraction.destination] drives routing:
  /// - `crm` — log to GitHub CRM (and Trello if action items are selected)
  /// - `trello` — create task cards; also logs to CRM when a real client is named
  ///   or action items are present (task-only notes without a client skip CRM)
  Future<ActivityEntry> confirm({
    required Capture capture,
    required Extraction extraction,
  }) async {
    await _ensureLoaded();

    final bool hasClient = extraction.client.trim().isNotEmpty &&
        extraction.client.toLowerCase() != 'unknown client';
    final bool hasSelectedTasks =
        extraction.actionItems.any((ActionItem a) => a.selected);
    final bool routesToTrello = extraction.routesToTrello;

    final bool writeCrm =
        extraction.destination == 'crm' || hasSelectedTasks || hasClient;
    final bool writeTrello = routesToTrello ||
        hasSelectedTasks ||
        extraction.updateType == UpdateType.followUp;

    CrmWriteResult crm = const CrmWriteResult(
      ok: true,
      contactId: '',
      contactName: '',
      action: 'skipped',
    );
    if (writeCrm) {
      crm = await _crm.upsertLead(
        extraction,
        transcript: capture.transcript,
        captureId: capture.id,
      );
      if (!crm.ok) {
        throw FormatException(crm.error ?? 'CRM write failed.');
      }
    }

    final List<ActionItem> selected =
        extraction.actionItems.where((ActionItem a) => a.selected).toList();
    bool taskOk = true;
    String? firstCardUrl;
    if (writeTrello) {
      final List<ActionItem> cards = selected.isNotEmpty
          ? selected
          : <ActionItem>[
              ActionItem(title: extraction.summary, due: extraction.followUpDate),
            ];
      for (final ActionItem item in cards) {
        final TrelloResult r = await _trello.createCard(
          title: item.title,
          description: 'For ${extraction.client} · logged from Mr. Rex mobile.',
          due: item.due,
        );
        taskOk = taskOk && r.ok;
        firstCardUrl ??= r.cardUrl;
      }
    }

    final String? trelloUrl = writeTrello
        ? (AppConfig.hasTrelloBoard ? AppConfig.trelloBoardUrl : firstCardUrl)
        : null;
    final String? crmWebUrl =
        writeCrm && AppConfig.hasCrmWeb ? AppConfig.crmWebUrl : crm.webUrl;

    final ActivityEntry entry = ActivityEntry(
      id: 'act-${DateTime.now().microsecondsSinceEpoch}',
      clientName: extraction.client,
      description: extraction.summary,
      updateType: extraction.updateType,
      timestamp: DateTime.now(),
      crmOk: writeCrm ? crm.ok : true,
      taskOk: writeTrello ? taskOk : true,
      isTask: writeTrello,
      contactId: crm.contactId.isEmpty ? null : crm.contactId,
      crmWebUrl: crmWebUrl,
      trelloUrl: trelloUrl,
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

  /// Interaction history for a contact, for the "show the history" view.
  Future<List<CrmInteraction>> historyFor(String contactRef) =>
      _crm.history(contactRef);

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
