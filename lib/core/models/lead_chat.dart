import 'package:equatable/equatable.dart';

import 'pipeline.dart';

/// One row of the brief tile a lead chat opens with.
///
/// `gap` marks a row that is a hole rather than a fact — MISSING: preferred
/// area. The web app renders those differently for a reason: a blank is
/// something to go and fill in, and showing it in the same weight as a known
/// fact is how it gets read as one.
class BriefRow extends Equatable {
  const BriefRow({required this.label, required this.value, required this.isGap});

  factory BriefRow.fromJson(Map<String, dynamic> json) => BriefRow(
        label: asString(json['label']),
        value: asString(json['value']),
        isGap: json['gap'] == true,
      );

  final String label;
  final String value;
  final bool isGap;

  @override
  List<Object?> get props => <Object?>[label, value, isGap];
}

/// The tile at the top of a lead chat: stage, what they want, what has been
/// sent, what is open, when you last spoke, what is missing.
///
/// Built server-side by the same `rex.chat.workflows.build_brief` the web app
/// uses, so the phone and the browser show the same card for the same lead.
class LeadBrief extends Equatable {
  const LeadBrief({
    required this.lead,
    required this.stage,
    required this.rows,
    required this.flags,
  });

  factory LeadBrief.fromJson(Map<String, dynamic> json) => LeadBrief(
        lead: asString(json['lead']),
        stage: asString(json['stage']),
        rows: asMaps(json['rows']).map(BriefRow.fromJson).toList(),
        flags: asStrings(json['flags']),
      );

  static const LeadBrief empty =
      LeadBrief(lead: '', stage: '', rows: <BriefRow>[], flags: <String>[]);

  final String lead;
  final String stage;
  final List<BriefRow> rows;
  final List<String> flags;

  bool get isEmpty => rows.isEmpty && stage.isEmpty;

  @override
  List<Object?> get props => <Object?>[lead, stage, rows, flags];
}

/// One message in a lead's thread.
class LeadChatMessage extends Equatable {
  const LeadChatMessage({
    required this.id,
    required this.role,
    required this.body,
    required this.source,
    required this.createdAt,
    this.pending = false,
  });

  factory LeadChatMessage.fromJson(Map<String, dynamic> json) => LeadChatMessage(
        id: asString(json['id']),
        role: asString(json['role']),
        body: asString(json['body']),
        source: asString(json['source']),
        createdAt: DateTime.tryParse(asString(json['created_at'])),
      );

  /// A turn on screen that has not reached the server yet.
  const LeadChatMessage.thinking()
      : this(
          id: '_pending',
          role: 'assistant',
          body: '',
          source: '',
          createdAt: null,
          pending: true,
        );

  final String id;
  final String role;
  final String body;

  /// Which surface it was typed on — 'mobile', or blank for the web app.
  final String source;
  final DateTime? createdAt;
  final bool pending;

  bool get isUser => role == 'user';

  /// Whether this turn came from the other client, which is worth marking:
  /// a thread that suddenly contains questions you did not ask is confusing
  /// until you know a colleague — or you, at a desk — asked them.
  bool get fromWeb => source.isEmpty || source == 'web';

  @override
  List<Object?> get props => <Object?>[id, role, body, createdAt, pending];
}

/// A lead's thread plus the tile it opens with.
class LeadChatThread extends Equatable {
  const LeadChatThread({
    required this.lead,
    required this.brief,
    required this.messages,
  });

  factory LeadChatThread.fromJson(Map<String, dynamic> json) => LeadChatThread(
        lead: Lead.fromJson(asMap(json['lead'])),
        brief: LeadBrief.fromJson(asMap(json['brief'])),
        messages:
            asMaps(json['messages']).map(LeadChatMessage.fromJson).toList(),
      );

  final Lead lead;
  final LeadBrief brief;
  final List<LeadChatMessage> messages;

  @override
  List<Object?> get props => <Object?>[lead, brief, messages];
}
