part of 'conversation_bloc.dart';

enum ConversationStatus { idle, thinking, ready, writing, written, undone, error }

class ConversationState extends Equatable {
  const ConversationState({
    this.status = ConversationStatus.idle,
    this.messages = const <ConversationMessage>[],
    this.source,
    this.extraction,
    this.contextContact,
    this.writtenCapture,
    this.activityEntry,
    this.message,
  });

  final ConversationStatus status;
  final List<ConversationMessage> messages;

  /// The pending capture this fulfils (post-meeting), if any.
  final Capture? source;

  /// Set once Rex has gathered enough to save.
  final Extraction? extraction;

  /// The matched CRM contact (deal value/status) shown on the save card.
  final CrmContact? contextContact;
  final Capture? writtenCapture;
  final ActivityEntry? activityEntry;
  final String? message;

  bool get busy =>
      status == ConversationStatus.thinking ||
      status == ConversationStatus.writing;
  bool get isReady => status == ConversationStatus.ready;
  bool get isWritten => status == ConversationStatus.written;

  ConversationState copyWith({
    ConversationStatus? status,
    List<ConversationMessage>? messages,
    Capture? source,
    Extraction? extraction,
    CrmContact? contextContact,
    Capture? writtenCapture,
    ActivityEntry? activityEntry,
    String? message,
  }) =>
      ConversationState(
        status: status ?? this.status,
        messages: messages ?? this.messages,
        source: source ?? this.source,
        extraction: extraction ?? this.extraction,
        contextContact: contextContact ?? this.contextContact,
        writtenCapture: writtenCapture ?? this.writtenCapture,
        activityEntry: activityEntry ?? this.activityEntry,
        message: message,
      );

  @override
  List<Object?> get props => <Object?>[
        status,
        messages,
        source,
        extraction,
        contextContact,
        writtenCapture,
        activityEntry,
        message,
      ];
}
