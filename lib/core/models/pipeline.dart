import 'package:equatable/equatable.dart';

/// Helpers for the loosely-typed JSON the API returns.
///
/// The API is deliberately tolerant — a missing field is an empty string, not
/// an error — so the client matches it. A lead that fails to parse because one
/// column was null is a lead the rep cannot open.
String asString(dynamic v) => v == null ? '' : v.toString();
int asInt(dynamic v) => v is int ? v : int.tryParse(asString(v)) ?? 0;
double asDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse(asString(v)) ?? 0;
List<String> asStrings(dynamic v) =>
    v is List ? v.map(asString).where((String s) => s.isNotEmpty).toList() : <String>[];

Map<String, dynamic> asMap(dynamic v) =>
    v is Map<String, dynamic> ? v : <String, dynamic>{};

List<Map<String, dynamic>> asMaps(dynamic v) => v is List
    ? v.whereType<Map<String, dynamic>>().toList()
    : <Map<String, dynamic>>[];

/// A pipeline stage. Mirrors the server's `STAGES`, which mirrors the database.
enum Stage {
  newLead('new', 'New'),
  contacted('contacted', 'Contacted'),
  qualified('qualified', 'Qualified'),
  proposal('proposal', 'Proposal'),
  won('won', 'Won'),
  lost('lost', 'Lost');

  const Stage(this.key, this.label);

  final String key;
  final String label;

  static Stage from(String key) => Stage.values.firstWhere(
        (Stage s) => s.key == key.toLowerCase(),
        orElse: () => Stage.newLead,
      );

  bool get isClosed => this == Stage.won || this == Stage.lost;

  /// The stages a board shows as columns — closed deals are a separate group.
  static List<Stage> get open => <Stage>[newLead, contacted, qualified, proposal];
}

/// How much attention a lead needs, as scored by `rex.intelligence`.
enum RiskLevel {
  healthy('healthy', 'On track'),
  needsAttention('needs_attention', 'Needs attention'),
  atRisk('at_risk', 'At risk');

  const RiskLevel(this.key, this.label);

  final String key;
  final String label;

  static RiskLevel from(String key) => RiskLevel.values.firstWhere(
        (RiskLevel r) => r.key == key.toLowerCase(),
        orElse: () => RiskLevel.healthy,
      );
}

/// One reason a lead scored the way it did.
class ScoreFactor extends Equatable {
  const ScoreFactor({required this.feature, required this.points, required this.reason});

  factory ScoreFactor.fromJson(Map<String, dynamic> json) => ScoreFactor(
        feature: asString(json['feature']),
        points: asInt(json['points']),
        reason: asString(json['reason']),
      );

  final String feature;
  final int points;
  final String reason;

  @override
  List<Object?> get props => <Object?>[feature, points, reason];
}

/// An entry on a lead's timeline. Append-only server-side, so read-only here.
class LeadActivity extends Equatable {
  const LeadActivity({
    required this.type,
    required this.actorType,
    required this.note,
    required this.createdAt,
  });

  factory LeadActivity.fromJson(Map<String, dynamic> json) => LeadActivity(
        type: asString(json['type']),
        actorType: asString(json['actor_type']),
        note: asString(json['note']),
        createdAt: DateTime.tryParse(asString(json['created_at'])),
      );

  final String type;
  final String actorType;
  final String note;
  final DateTime? createdAt;

  /// "call.logged" → "Call logged"
  String get label {
    final String cleaned = type.replaceAll('.', ' ').replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) return 'Update';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  @override
  List<Object?> get props => <Object?>[type, actorType, note, createdAt];
}

/// A lead on the pipeline board.
class Lead extends Equatable {
  const Lead({
    required this.id,
    required this.name,
    required this.company,
    required this.email,
    required this.phone,
    required this.stage,
    required this.owner,
    required this.value,
    required this.valueFmt,
    required this.locality,
    required this.budget,
    required this.requirement,
    required this.source,
    required this.nextFollowUp,
    required this.updatedAt,
    required this.score,
    required this.priority,
    required this.risk,
    required this.riskReasons,
    required this.topFactors,
    required this.daysSinceActivity,
    required this.followUpDue,
    this.notes = '',
    this.activities = const <LeadActivity>[],
  });

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
        id: asString(json['id']),
        name: asString(json['name']),
        company: asString(json['company']),
        email: asString(json['email']),
        phone: asString(json['phone']),
        stage: Stage.from(asString(json['stage'])),
        owner: asString(json['owner']),
        value: asDouble(json['value']),
        valueFmt: asString(json['value_fmt']),
        locality: asString(json['locality']),
        budget: asString(json['budget']),
        requirement: asString(json['requirement']),
        source: asString(json['source']),
        nextFollowUp: asString(json['next_follow_up']),
        updatedAt: DateTime.tryParse(asString(json['updated_at'])),
        score: asInt(json['score']),
        priority: asInt(json['priority']),
        risk: RiskLevel.from(asString(json['risk'])),
        riskReasons: asStrings(json['risk_reasons']),
        topFactors: asMaps(json['top_factors']).map(ScoreFactor.fromJson).toList(),
        daysSinceActivity: asInt(json['days_since_activity']),
        followUpDue: json['follow_up_due'] == true,
        notes: asString(json['notes']),
        activities: asMaps(json['activities']).map(LeadActivity.fromJson).toList(),
      );

  final String id;
  final String name;
  final String company;
  final String email;
  final String phone;
  final Stage stage;
  final String owner;
  final double value;
  final String valueFmt;
  final String locality;
  final String budget;
  final String requirement;
  final String source;
  final String nextFollowUp;
  final DateTime? updatedAt;
  final int score;
  final int priority;
  final RiskLevel risk;
  final List<String> riskReasons;
  final List<ScoreFactor> topFactors;
  final int daysSinceActivity;
  final bool followUpDue;
  final String notes;
  final List<LeadActivity> activities;

  /// What to put on the card. A lead may be a person, a company, or both.
  String get title => name.isNotEmpty ? name : company;

  String get subtitle => name.isNotEmpty && company.isNotEmpty ? company : locality;

  /// The server redacts notes a rep may not read, using this exact sentence.
  bool get notesArePrivate => notes == 'Private to the owning rep';

  /// Whether this lead has anything worth badging.
  ///
  /// A green "on track" badge on every healthy lead is noise that trains people
  /// to stop reading badges, so the healthy case shows nothing — and callers
  /// ask this rather than each deciding for themselves what counts.
  bool get needsAttention => risk != RiskLevel.healthy || followUpDue;

  /// What a card shows for money. `value` is often unset while `budget` holds
  /// the real number as text ("1.4 cr") — showing nothing when a budget exists
  /// makes every lead look worthless.
  String get moneyLabel => valueFmt.isNotEmpty ? valueFmt : budget;

  @override
  List<Object?> get props => <Object?>[id, stage, score, updatedAt, activities.length];
}

/// The counters above the board.
class PipelineStats extends Equatable {
  const PipelineStats({
    required this.active,
    required this.won,
    required this.lost,
    required this.total,
    required this.valueFmt,
  });

  factory PipelineStats.fromJson(Map<String, dynamic> json) => PipelineStats(
        active: asInt(json['active']),
        won: asInt(json['won']),
        lost: asInt(json['lost']),
        total: asInt(json['total']),
        valueFmt: asString(json['pipeline_value_fmt']),
      );

  static const PipelineStats empty =
      PipelineStats(active: 0, won: 0, lost: 0, total: 0, valueFmt: '₹0');

  final int active;
  final int won;
  final int lost;
  final int total;
  final String valueFmt;

  @override
  List<Object?> get props => <Object?>[active, won, lost, total, valueFmt];
}

/// The whole board in one object.
class PipelineBoard extends Equatable {
  const PipelineBoard({required this.stats, required this.leads});

  factory PipelineBoard.fromJson(Map<String, dynamic> json) => PipelineBoard(
        stats: PipelineStats.fromJson(asMap(json['stats'])),
        leads: asMaps(json['leads']).map(Lead.fromJson).toList(),
      );

  static const PipelineBoard empty =
      PipelineBoard(stats: PipelineStats.empty, leads: <Lead>[]);

  final PipelineStats stats;
  final List<Lead> leads;

  List<Lead> inStage(Stage stage) =>
      leads.where((Lead l) => l.stage == stage).toList();

  int countIn(Stage stage) => leads.where((Lead l) => l.stage == stage).length;

  @override
  List<Object?> get props => <Object?>[stats, leads];
}
