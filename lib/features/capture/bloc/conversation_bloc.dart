import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/activity.dart';
import '../../../core/models/capture.dart';
import '../../../core/models/conversation.dart';
import '../../../core/models/crm.dart';
import '../../../core/models/extraction.dart';
import '../../../core/repository/capture_repository.dart';
import '../../../core/services/ai/ai_service.dart';
import '../../../core/services/crm/leads_crm_service.dart';
import '../../../core/utils/formatters.dart';

part 'conversation_event.dart';
part 'conversation_state.dart';

/// Drives the conversational capture (spec §6.1, made interactive): Rex asks
/// follow-up questions via Gemini until it has enough, then writes a CRM
/// record (created or updated by name) and/or Trello card.
class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  ConversationBloc({
    required AiService ai,
    required CaptureRepository captures,
    required LeadsCrmService crm,
    Capture? source,
  })  : _ai = ai,
        _captures = captures,
        _crm = crm,
        super(ConversationState(source: source)) {
    on<ConversationOpened>(_onOpened);
    on<ConversationSent>(_onSent);
    on<ConversationConfirmed>(_onConfirmed);
    on<ConversationUndoRequested>(_onUndo);
    on<ConversationReset>(_onReset);
  }

  final AiService _ai;
  final CaptureRepository _captures;
  final LeadsCrmService _crm;
  List<String> _hints = <String>[];

  /// The resolved client's recent CRM history (fed to Gemini once known) so
  /// Rex can ask sharper, context-aware questions.
  String? _context;

  Future<void> _onOpened(
    ConversationOpened event,
    Emitter<ConversationState> emit,
  ) async {
    // Best-effort: existing client names so Gemini updates rather than dupes.
    try {
      _hints = (await _crm.listLeads())
          .map((c) => c.name)
          .where((String n) => n.isNotEmpty)
          .toList();
    } catch (_) {
      _hints = <String>[];
    }
    // Post-meeting: we already know the client — load their history upfront.
    if (state.source != null) {
      await _loadContext(state.source!.clientName);
    }
    final String greeting = state.source != null
        ? 'Hey! How did your meeting with ${state.source!.clientName} go?'
        : 'Hey! Who did you meet or speak with, and how did it go?';
    emit(state.copyWith(messages: <ConversationMessage>[
      ConversationMessage(role: ChatRole.rex, text: greeting),
    ]));
  }

  /// Once a known client is mentioned, fetch their recent interactions once.
  Future<void> _ensureContext(List<ConversationMessage> messages) async {
    if (_context != null) return;
    final String said = messages
        .where((ConversationMessage m) => m.role == ChatRole.user)
        .map((ConversationMessage m) => m.text)
        .join(' ')
        .toLowerCase();
    for (final String name in _hints) {
      final String first = name.toLowerCase().split(' ').first;
      if (first.length > 2 && said.contains(first)) {
        await _loadContext(name);
        return;
      }
    }
  }

  Future<void> _loadContext(String name) async {
    try {
      final List<CrmInteraction> history = await _crm.history(name);
      if (history.isEmpty) {
        _context = 'No prior interactions are logged for $name yet.';
      } else {
        final String lines = history
            .take(5)
            .map((CrmInteraction i) =>
                '- ${Formatters.dayShort(i.createdAt)}: ${i.body}')
            .join('\n');
        _context = 'Recent CRM history for $name:\n$lines';
      }
    } catch (_) {
      _context = null;
    }
  }

  Future<void> _onSent(
    ConversationSent event,
    Emitter<ConversationState> emit,
  ) async {
    final String text = event.text.trim();
    if (text.isEmpty || state.busy) return;

    emit(state.copyWith(
      status: ConversationStatus.thinking,
      messages: <ConversationMessage>[
        ...state.messages,
        ConversationMessage(role: ChatRole.user, text: text),
        const ConversationMessage(role: ChatRole.rex, text: '', pending: true),
      ],
    ));

    try {
      final List<ConversationMessage> history = state.messages
          .where((ConversationMessage m) => !m.pending)
          .toList();
      await _ensureContext(history);
      final ConversationResult result = await _ai.converse(
        history: history,
        clientHints: _hints,
        clientContext: _context,
      );

      final List<ConversationMessage> resolved =
          List<ConversationMessage>.of(state.messages)
            ..removeLast()
            ..add(ConversationMessage(role: ChatRole.rex, text: result.reply));

      final bool ready = result.done && (result.extraction?.isValid ?? false);
      emit(state.copyWith(
        messages: resolved,
        status: ready ? ConversationStatus.ready : ConversationStatus.idle,
        extraction: ready ? result.extraction : null,
      ));
    } catch (_) {
      final List<ConversationMessage> failed =
          List<ConversationMessage>.of(state.messages)
            ..removeLast()
            ..add(const ConversationMessage(
              role: ChatRole.rex,
              text: 'Sorry, I had trouble there — could you say that again?',
            ));
      emit(state.copyWith(messages: failed, status: ConversationStatus.idle));
    }
  }

  Future<void> _onConfirmed(
    ConversationConfirmed event,
    Emitter<ConversationState> emit,
  ) async {
    final Extraction? extraction = state.extraction;
    if (extraction == null || !extraction.isValid) return;
    emit(state.copyWith(status: ConversationStatus.writing));

    final Capture capture = state.source ??
        Capture(
          id: 'cap-${DateTime.now().microsecondsSinceEpoch}',
          clientName: extraction.client,
          summary: extraction.summary,
          createdAt: DateTime.now(),
          transcript: _transcript(),
        );

    final ActivityEntry entry =
        await _captures.confirm(capture: capture, extraction: extraction);
    emit(state.copyWith(
      status: ConversationStatus.written,
      writtenCapture: capture,
      activityEntry: entry,
    ));
  }

  Future<void> _onUndo(
    ConversationUndoRequested event,
    Emitter<ConversationState> emit,
  ) async {
    final ActivityEntry? entry = state.activityEntry;
    if (entry == null) return;
    await _captures.undo(entry, captureId: state.writtenCapture?.id);
    emit(state.copyWith(status: ConversationStatus.undone));
  }

  void _onReset(ConversationReset event, Emitter<ConversationState> emit) {
    _context = null;
    emit(ConversationState(source: state.source));
    add(const ConversationOpened());
  }

  String _transcript() => state.messages
      .where((ConversationMessage m) => m.role == ChatRole.user)
      .map((ConversationMessage m) => m.text)
      .join('. ');
}
