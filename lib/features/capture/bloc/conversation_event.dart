part of 'conversation_bloc.dart';

sealed class ConversationEvent extends Equatable {
  const ConversationEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Start the conversation (loads client hints + Rex's opening line).
final class ConversationOpened extends ConversationEvent {
  const ConversationOpened();
}

/// The rep sent a message (typed or transcribed).
final class ConversationSent extends ConversationEvent {
  const ConversationSent(this.text);

  final String text;

  @override
  List<Object?> get props => <Object?>[text];
}

/// Save the gathered extraction to the CRM / Trello.
final class ConversationConfirmed extends ConversationEvent {
  const ConversationConfirmed();
}

final class ConversationUndoRequested extends ConversationEvent {
  const ConversationUndoRequested();
}

final class ConversationReset extends ConversationEvent {
  const ConversationReset();
}
