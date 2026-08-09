import 'package:equatable/equatable.dart';

import 'listing.dart';
import 'pipeline.dart';

/// Something Ona offers to do next, as a tappable chip.
///
/// Anything Ona *asks* must be tappable. "Where would you like to start?" is
/// only a question if the answer is one tap away — otherwise the rep types
/// "sure" and is told they were not understood.
class OnaOffer extends Equatable {
  const OnaOffer({required this.label, required this.prompt});

  factory OnaOffer.fromJson(Map<String, dynamic> json) => OnaOffer(
        label: asString(json['label']).isNotEmpty
            ? asString(json['label'])
            : asString(json['phrase']),
        prompt: asString(json['prompt']),
      );

  final String label;
  final String prompt;

  @override
  List<Object?> get props => <Object?>[label, prompt];
}

/// A write Ona is proposing but has not performed.
///
/// The server returns these instead of executing them. Ona proposes, the user
/// confirms, and only then does anything write — no exception for "the user
/// clearly meant it".
class OnaHandoff extends Equatable {
  const OnaHandoff({required this.kind, required this.params, required this.message});

  final String kind;
  final Map<String, dynamic> params;
  final String message;

  String get contactName =>
      asString(params['contact_name']).isNotEmpty
          ? asString(params['contact_name'])
          : asString(params['name']);

  String get contactId => asString(params['contact_id']);

  /// The verb for the confirm button — what the user is actually approving.
  String get actionLabel {
    switch (kind) {
      case 'share_listings':
        return 'Open share composer';
      case 'add_lead':
        return 'Add this lead';
      case 'message_lead':
        return 'Draft the message';
      case 'log_activity':
        return 'Log it';
      case 'reschedule':
        return 'Move the follow-up';
      case 'lead':
        return 'Open lead';
      default:
        return 'Continue';
    }
  }

  /// Whether this handoff writes to the CRM if the user approves.
  bool get writes => const <String>{
        'add_lead',
        'log_activity',
        'reschedule',
      }.contains(kind);

  @override
  List<Object?> get props => <Object?>[kind, params, message];
}

/// One answer from the query engine.
///
/// Deliberately keeps the server's per-intent shape rather than flattening it.
/// The renderers switch on [intent] exactly as the web app's do, so a briefing
/// stays a briefing and a listings result stays a list of properties.
class OnaAnswer extends Equatable {
  const OnaAnswer({
    required this.ok,
    required this.intent,
    required this.hasData,
    required this.message,
    required this.offers,
    required this.listings,
    required this.deals,
    required this.handoff,
    required this.raw,
  });

  factory OnaAnswer.fromJson(Map<String, dynamic> json) {
    final String handoffKind = asString(json['handoff']);
    return OnaAnswer(
      ok: json['ok'] != false,
      intent: asString(json['intent']),
      hasData: json['has_data'] == true,
      message: asString(json['message']),
      offers: asMaps(json['offers']).map(OnaOffer.fromJson).toList(),
      listings: asMaps(json['listings']).map(Listing.fromJson).toList(),
      deals: asMaps(json['deals']),
      handoff: handoffKind.isEmpty
          ? null
          : OnaHandoff(
              kind: handoffKind,
              params: asMap(json['params']),
              message: asString(json['message']),
            ),
      raw: json,
    );
  }

  final bool ok;
  final String intent;
  final bool hasData;
  final String message;
  final List<OnaOffer> offers;
  final List<Listing> listings;
  final List<Map<String, dynamic>> deals;
  final OnaHandoff? handoff;
  final Map<String, dynamic> raw;

  /// The briefing's sub-sections, when this is a briefing.
  Map<String, dynamic> get morning => asMap(raw['morning']);
  Map<String, dynamic> get tasks => asMap(raw['tasks']);
  Map<String, dynamic> get risk => asMap(raw['risk']);
  Map<String, dynamic> get pipeline => asMap(raw['pipeline']);

  bool get isBriefing => intent == 'briefing';

  @override
  List<Object?> get props => <Object?>[intent, message, hasData, listings, deals];
}

/// A question Ona needs answered before it can act.
class OnaClarify extends Equatable {
  const OnaClarify({required this.question, required this.options});

  factory OnaClarify.fromJson(Map<String, dynamic> json) => OnaClarify(
        question: asString(json['question']),
        options: asStrings(json['options']),
      );

  final String question;
  final List<String> options;

  @override
  List<Object?> get props => <Object?>[question, options];
}

/// The server's reply to one message: what it understood, and what it did.
class OnaReply extends Equatable {
  const OnaReply({
    required this.plan,
    required this.understood,
    required this.summary,
    required this.clarify,
    required this.needsConfirmation,
    required this.answers,
  });

  factory OnaReply.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> clarifyRaw = asMap(json['clarify']);
    return OnaReply(
      plan: asMap(json['plan']),
      understood: asStrings(json['understood']),
      summary: asStrings(json['summary']),
      clarify: clarifyRaw.isEmpty ? null : OnaClarify.fromJson(clarifyRaw),
      needsConfirmation: json['needs_confirmation'] == true,
      answers: asMaps(json['answers']).map(OnaAnswer.fromJson).toList(),
    );
  }

  final Map<String, dynamic> plan;
  final List<String> understood;
  final List<String> summary;
  final OnaClarify? clarify;
  final bool needsConfirmation;
  final List<OnaAnswer> answers;

  /// True when Ona stopped to ask rather than answering.
  bool get isWaitingOnUser => clarify != null || needsConfirmation;

  @override
  List<Object?> get props =>
      <Object?>[understood, summary, clarify, needsConfirmation, answers];
}

/// Who said a thing in the thread.
enum Speaker { user, ona }

/// One bubble in the conversation.
///
/// A turn holds everything needed to render it, including the plan that
/// produced it — because when Ona asks a clarifying question, the reply has to
/// carry that plan back to the server. There is no session on the other end.
class OnaTurn extends Equatable {
  const OnaTurn({
    required this.speaker,
    required this.text,
    this.reply,
    this.pending = false,
    this.error = '',
    this.receipt,
  });

  const OnaTurn.user(String text) : this(speaker: Speaker.user, text: text);

  const OnaTurn.thinking() : this(speaker: Speaker.ona, text: '', pending: true);

  final Speaker speaker;
  final String text;
  final OnaReply? reply;
  final bool pending;
  final String error;

  /// The record as stored, after a confirmed write. Rendered as a receipt so
  /// the user sees what landed without leaving the conversation.
  final Lead? receipt;

  bool get isUser => speaker == Speaker.user;
  bool get hasError => error.isNotEmpty;

  List<OnaAnswer> get answers => reply?.answers ?? const <OnaAnswer>[];

  /// The one write this turn is proposing, if any.
  OnaHandoff? get handoff {
    for (final OnaAnswer a in answers) {
      if (a.handoff != null) return a.handoff;
    }
    return null;
  }

  OnaTurn copyWith({
    String? text,
    OnaReply? reply,
    bool? pending,
    String? error,
    Lead? receipt,
  }) =>
      OnaTurn(
        speaker: speaker,
        text: text ?? this.text,
        reply: reply ?? this.reply,
        pending: pending ?? this.pending,
        error: error ?? this.error,
        receipt: receipt ?? this.receipt,
      );

  @override
  List<Object?> get props =>
      <Object?>[speaker, text, reply, pending, error, receipt];
}
