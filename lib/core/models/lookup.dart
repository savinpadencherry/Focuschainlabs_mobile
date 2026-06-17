import 'package:equatable/equatable.dart';

/// A grounding citation for a lookup answer (F1: answers cite the source
/// record/document; no fabricated facts).
class Citation extends Equatable {
  const Citation({required this.label, required this.type});

  final String label;
  final String type; // e.g. 'CRM record', 'Product doc', 'Email'

  @override
  List<Object?> get props => <Object?>[label, type];
}

/// A grounded answer returned for an F1 lookup query. When [clientId] is set,
/// the UI renders a rich "client 360"; otherwise a knowledge-base answer.
class LookupAnswer extends Equatable {
  const LookupAnswer({
    required this.answer,
    this.clientId,
    this.citations = const <Citation>[],
  });

  final String answer;
  final String? clientId;
  final List<Citation> citations;

  bool get isClient360 => clientId != null;

  @override
  List<Object?> get props => <Object?>[answer, clientId, citations];
}

/// Author of a message in the lookup conversation.
enum ChatRole { user, rex }

/// One turn in the conversational lookup thread (F1 voice/typed Q&A).
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.role,
    required this.text,
    this.answer,
    this.pending = false,
  });

  final ChatRole role;
  final String text;
  final LookupAnswer? answer;
  final bool pending;

  @override
  List<Object?> get props => <Object?>[role, text, answer, pending];
}
