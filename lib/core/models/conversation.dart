import 'package:equatable/equatable.dart';

import 'extraction.dart';
import 'lookup.dart' show ChatRole;

export 'lookup.dart' show ChatRole;

/// One message in the capture conversation (the rep or Rex).
class ConversationMessage extends Equatable {
  const ConversationMessage({
    required this.role,
    required this.text,
    this.pending = false,
  });

  final ChatRole role;
  final String text;
  final bool pending;

  Map<String, dynamic> toGeminiTurn() => <String, dynamic>{
        'role': role == ChatRole.user ? 'user' : 'model',
        'parts': <dynamic>[
          <String, dynamic>{'text': text},
        ],
      };

  @override
  List<Object?> get props => <Object?>[role, text, pending];
}

/// Gemini's response each turn: a conversational [reply], whether it now has
/// enough to log ([done]), and the structured [extraction] once done.
class ConversationResult extends Equatable {
  const ConversationResult({
    required this.reply,
    required this.done,
    this.extraction,
  });

  final String reply;
  final bool done;
  final Extraction? extraction;

  factory ConversationResult.fromJson(Map<String, dynamic> json) {
    final dynamic ex = json['extraction'];
    return ConversationResult(
      reply: json['reply']?.toString() ?? '',
      done: json['done'] == true,
      extraction: ex is Map<String, dynamic> ? Extraction.fromJson(ex) : null,
    );
  }

  @override
  List<Object?> get props => <Object?>[reply, done, extraction];
}
