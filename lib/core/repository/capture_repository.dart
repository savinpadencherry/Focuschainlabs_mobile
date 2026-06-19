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

  /// Writes a confirmed capture and fans out (F5–F7): the note is logged to the
  /// CRM as an interaction; selected action items (and any follow-up) become
  /// Trello cards. Routing follows the product flow — a follow-up is primarily
  /// a *task* (→ Trello board), everything else is a *CRM update* (→ CRM,
  /// shown in desktop view with its interaction history).
  Future<ActivityEntry> confirm({
    required Capture capture,
    required Extraction extraction,
  }) async {
    await _ensureLoaded();

    // The AI router decides CRM vs Trello (a bare follow-up also counts as task).
    final bool isTask =
        extraction.routesToTrello || extraction.updateType == UpdateType.followUp;

    // 1) CRM — always log the spoken update against the contact.
    final CrmWriteResult crm =
        await _crm.upsertLead(extraction, transcript: capture.transcript);

    // 2) Trello — push selected action items; for a bare follow-up, push one
    //    card built from the summary so the task still lands on the board.
    final List<ActionItem> selected =
        extraction.actionItems.where((ActionItem a) => a.selected).toList();
    final bool hasTaskWork = selected.isNotEmpty || isTask;
    bool taskOk = true;
    String? firstCardUrl;
    if (hasTaskWork) {
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

    final String? trelloUrl = hasTaskWork
        ? (AppConfig.hasTrelloBoard ? AppConfig.trelloBoardUrl : firstCardUrl)
        : null;
    final String? crmWebUrl =
        AppConfig.hasCrmWeb ? AppConfig.crmWebUrl : crm.webUrl;

    final ActivityEntry entry = ActivityEntry(
      id: 'act-${DateTime.now().microsecondsSinceEpoch}',
      clientName: extraction.client,
      description: extraction.summary,
      updateType: extraction.updateType,
      timestamp: DateTime.now(),
      crmOk: crm.ok,
      taskOk: taskOk,
      isTask: isTask,
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
