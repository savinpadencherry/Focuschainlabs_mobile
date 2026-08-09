import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/ona.dart';
import '../../../core/models/pipeline.dart';
import '../../../core/repository/crm_repository.dart';
import '../../../core/services/api/secona_api.dart';

part 'ona_event.dart';
part 'ona_state.dart';

/// The Ask Ona thread.
///
/// The bloc holds the conversation *and* the pending plan, because the server
/// deliberately holds neither. When Ona asks a clarifying question, the plan
/// that produced it stays here until the user answers, then travels back with
/// the answer. Wherever Ona asks a question, something must hold enough state
/// to hear the reply — on this surface, that is this class.
class OnaBloc extends Bloc<OnaEvent, OnaState> {
  OnaBloc({required CrmRepository repository})
      : _repository = repository,
        super(const OnaState()) {
    on<OnaOpened>(_onOpened);
    on<OnaAsked>(_onAsked);
    on<OnaConfirmed>(_onConfirmed);
    on<OnaDeclined>(_onDeclined);
    on<OnaActionApproved>(_onActionApproved);
    on<OnaCleared>(_onCleared);
  }

  final CrmRepository _repository;

  /// Open with the morning brief rather than an empty box.
  ///
  /// The brief is what a rep opens the app for, and it is also what warms the
  /// day's data. An empty chat with a blinking cursor asks the user to think of
  /// something; a brief tells them what is already waiting.
  Future<void> _onOpened(OnaOpened event, Emitter<OnaState> emit) async {
    if (state.turns.isNotEmpty) return;
    emit(state.copyWith(status: OnaStatus.loading));
    try {
      final OnaAnswer brief = await _repository.briefing();
      emit(state.copyWith(
        status: OnaStatus.ready,
        turns: <OnaTurn>[
          OnaTurn(
            speaker: Speaker.ona,
            text: brief.message,
            reply: OnaReply(
              plan: const <String, dynamic>{},
              understood: const <String>[],
              summary: const <String>[],
              clarify: null,
              needsConfirmation: false,
              answers: <OnaAnswer>[brief],
            ),
          ),
        ],
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(status: OnaStatus.ready, error: e.message));
    }
  }

  Future<void> _onAsked(OnaAsked event, Emitter<OnaState> emit) async {
    final String query = event.query.trim();
    if (query.isEmpty || state.busy) return;

    final List<OnaTurn> thread = <OnaTurn>[
      ...state.turns,
      OnaTurn.user(query),
      const OnaTurn.thinking(),
    ];
    // The pending plan is consumed by this message, whatever the outcome —
    // leaving it set would make the *next* unrelated question look like an
    // answer to a question Ona has stopped asking.
    final Map<String, dynamic>? pending = state.pendingPlan;
    emit(state.copyWith(
      turns: thread,
      busy: true,
      error: '',
      clearPendingPlan: true,
    ));

    try {
      final OnaReply reply = await _repository.ask(
        query,
        history: state.turns,
        fromChip: event.fromChip,
        pendingPlan: pending,
      );
      _land(emit, reply);
    } on ApiException catch (e) {
      _fail(emit, e.message);
    }
  }

  Future<void> _onConfirmed(OnaConfirmed event, Emitter<OnaState> emit) async {
    final Map<String, dynamic>? plan = state.pendingPlan;
    if (plan == null || state.busy) return;

    emit(state.copyWith(
      turns: <OnaTurn>[...state.turns, const OnaTurn.thinking()],
      busy: true,
      clearPendingPlan: true,
    ));

    try {
      _land(emit, await _repository.confirm(plan));
    } on ApiException catch (e) {
      _fail(emit, e.message);
    }
  }

  void _onDeclined(OnaDeclined event, Emitter<OnaState> emit) {
    emit(state.copyWith(
      clearPendingPlan: true,
      turns: <OnaTurn>[
        ...state.turns,
        const OnaTurn(
          speaker: Speaker.ona,
          text: 'Left it alone. What would you like to do instead?',
        ),
      ],
    ));
  }

  /// The user pressed the button on a proposed write. Only now does it happen.
  Future<void> _onActionApproved(
    OnaActionApproved event,
    Emitter<OnaState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(
      turns: <OnaTurn>[...state.turns, const OnaTurn.thinking()],
      busy: true,
    ));

    try {
      final Lead stored = await _repository.act(event.action, event.params);
      final List<OnaTurn> resolved = List<OnaTurn>.of(state.turns)
        ..removeLast()
        ..add(OnaTurn(
          speaker: Speaker.ona,
          text: 'Done — here is what I saved.',
          receipt: stored,
        ));
      emit(state.copyWith(turns: resolved, busy: false));
    } on ApiException catch (e) {
      _fail(emit, e.message);
    }
  }

  void _onCleared(OnaCleared event, Emitter<OnaState> emit) {
    emit(const OnaState());
    add(const OnaOpened());
  }

  /// Replace the thinking bubble with the reply, and remember any open question.
  void _land(Emitter<OnaState> emit, OnaReply reply) {
    final String text = reply.clarify?.question ??
        (reply.answers.isNotEmpty ? reply.answers.first.message : '');

    final List<OnaTurn> resolved = List<OnaTurn>.of(state.turns)
      ..removeLast()
      ..add(OnaTurn(speaker: Speaker.ona, text: text, reply: reply));

    emit(state.copyWith(
      turns: resolved,
      busy: false,
      // Held only while Ona is actually waiting on the user.
      pendingPlan: reply.isWaitingOnUser ? reply.plan : null,
      clearPendingPlan: !reply.isWaitingOnUser,
    ));
  }

  void _fail(Emitter<OnaState> emit, String message) {
    final List<OnaTurn> failed = List<OnaTurn>.of(state.turns)
      ..removeLast()
      ..add(OnaTurn(speaker: Speaker.ona, text: '', error: message));
    emit(state.copyWith(turns: failed, busy: false));
  }
}
