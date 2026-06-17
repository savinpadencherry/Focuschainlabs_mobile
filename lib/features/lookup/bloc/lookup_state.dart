part of 'lookup_bloc.dart';

class LookupState extends Equatable {
  const LookupState({
    this.messages = const <ChatMessage>[],
    this.busy = false,
  });

  final List<ChatMessage> messages;
  final bool busy;

  bool get isEmpty => messages.isEmpty;

  LookupState copyWith({List<ChatMessage>? messages, bool? busy}) => LookupState(
        messages: messages ?? this.messages,
        busy: busy ?? this.busy,
      );

  @override
  List<Object?> get props => <Object?>[messages, busy];
}
