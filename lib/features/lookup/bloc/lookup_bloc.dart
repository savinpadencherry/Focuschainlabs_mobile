import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/lookup.dart';
import '../../../core/repository/lookup_repository.dart';

part 'lookup_event.dart';
part 'lookup_state.dart';

/// Manages the F1 conversational lookup thread: each question is appended, a
/// pending Rex bubble is shown, then replaced with a grounded, cited answer.
class LookupBloc extends Bloc<LookupEvent, LookupState> {
  LookupBloc({required LookupRepository repository})
      : _repository = repository,
        super(const LookupState()) {
    on<LookupAsked>(_onAsked);
    on<LookupCleared>(_onCleared);
  }

  final LookupRepository _repository;

  Future<void> _onAsked(LookupAsked event, Emitter<LookupState> emit) async {
    final String query = event.query.trim();
    if (query.isEmpty) return;

    final List<ChatMessage> thread = <ChatMessage>[
      ...state.messages,
      ChatMessage(role: ChatRole.user, text: query),
      const ChatMessage(role: ChatRole.rex, text: '', pending: true),
    ];
    emit(state.copyWith(messages: thread, busy: true));

    try {
      final LookupAnswer answer = await _repository.ask(query);
      final List<ChatMessage> resolved = List<ChatMessage>.of(state.messages)
        ..removeLast()
        ..add(ChatMessage(role: ChatRole.rex, text: answer.answer, answer: answer));
      emit(state.copyWith(messages: resolved, busy: false));
    } catch (_) {
      final List<ChatMessage> failed = List<ChatMessage>.of(state.messages)
        ..removeLast()
        ..add(const ChatMessage(
          role: ChatRole.rex,
          text: 'Something went wrong fetching that. Please try again.',
        ));
      emit(state.copyWith(messages: failed, busy: false));
    }
  }

  void _onCleared(LookupCleared event, Emitter<LookupState> emit) {
    emit(const LookupState());
  }
}
