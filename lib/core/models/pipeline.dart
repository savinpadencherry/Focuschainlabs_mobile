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

/// A pipeline stage.
///
/// Not an enum. The stage list belongs to the CRM — new, contacted,
/// interested, site_visits, offer, negotiation, agreement, closed — and it is
/// sent with the board rather than restated here. The enum this replaces knew
/// six stages, two of which (`qualified`, `proposal`) are not stages at all
/// but legacy aliases, and it silently rendered everything it did not
/// recognise as "New". A lead at Site Visits therefore read as a New lead on
/// the phone and as Site Visits in the browser.
///
/// The label comes from the server too, so the two surfaces cannot disagree
/// about what `site_visits` is called.
class Stage extends Equatable {
  const Stage({required this.key, required this.label});

  factory Stage.fromJson(Map<String, dynamic> json) => Stage(
        key: asString(json['key']),
        label: asString(json['label']),
      );

  /// For a lead, whose payload carries the pair inline.
  factory Stage.of(String key, String label) => Stage(
        key: key.toLowerCase(),
        label: label.isNotEmpty ? label : _titleCase(key),
      );

  final String key;
  final String label;

  static String _titleCase(String key) {
    if (key.isEmpty) return 'New Lead';
    return key
        .split(RegExp(r'[_\s]+'))
        .where((String w) => w.isNotEmpty)
        .map((String w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  /// A finished outcome rather than a step on the way.
  bool get isClosed => const <String>{'won', 'lost', 'closed'}.contains(key);

  @override
  List<Object?> get props => <Object?>[key];
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

/// One labelled fact on a lead, exactly as the server named it.
class LeadField extends Equatable {
  const LeadField({required this.key, required this.label, required this.value});

  factory LeadField.fromJson(Map<String, dynamic> json) => LeadField(
        key: asString(json['key']),
        label: asString(json['label']),
        value: asString(json['value']),
      );

  final String key;
  final String label;
  final String value;

  @override
  List<Object?> get props => <Object?>[key, label, value];
}

/// A section of the lead page — "What they want", "Deal", and so on.
///
/// The grouping is sent, not decided here. Which section `budget_stretch`
/// belongs in is a product decision, and a copy of it on the phone is a copy
/// that drifts from the browser the first time either is edited.
class LeadFieldGroup extends Equatable {
  const LeadFieldGroup({
    required this.key,
    required this.label,
    required this.fields,
  });

  factory LeadFieldGroup.fromJson(Map<String, dynamic> json) => LeadFieldGroup(
        key: asString(json['key']),
        label: asString(json['label']),
        fields: asMaps(json['fields']).map(LeadField.fromJson).toList(),
      );

  final String key;
  final String label;
  final List<LeadField> fields;

  @override
  List<Object?> get props => <Object?>[key, label, fields];
}

/// Someone else around the deal — the spouse who has to agree, the brother
/// who is paying, the tenant who has to move out.
///
/// `stance` is the whole point: knowing that the person you are about to ring
/// is recorded as the blocker changes the call.
class LeadPerson extends Equatable {
  const LeadPerson({
    required this.id,
    required this.name,
    required this.role,
    required this.stance,
    required this.phone,
    required this.email,
    required this.notes,
  });

  factory LeadPerson.fromJson(Map<String, dynamic> json) => LeadPerson(
        id: asString(json['id']),
        name: asString(json['name']),
        role: asString(json['role']),
        stance: asString(json['stance']),
        phone: asString(json['phone']),
        email: asString(json['email']),
        notes: asString(json['notes']),
      );

  final String id;
  final String name;
  final String role;
  final String stance;
  final String phone;
  final String email;
  final String notes;

  bool get isChampion => stance.toLowerCase() == 'champion';
  bool get isBlocker => stance.toLowerCase() == 'blocker';

  /// "Spouse · champion", or whichever half is on file.
  String get subtitle => <String>[role, stance]
      .where((String s) => s.isNotEmpty)
      .join(' · ');

  @override
  List<Object?> get props => <Object?>[id, name, role, stance, phone, email];
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
    this.bhk = '',
    this.propertyType = '',
    this.possession = '',
    this.dealStatus = '',
    this.signal = '',
    this.openingLine = '',
    this.aiSummary = '',
    this.tags = const <String>[],
    this.fieldGroups = const <LeadFieldGroup>[],
    this.people = const <LeadPerson>[],
    this.createdAt,
  });

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
        id: asString(json['id']),
        name: asString(json['name']),
        company: asString(json['company']),
        email: asString(json['email']),
        phone: asString(json['phone']),
        stage: Stage.of(asString(json['stage']), asString(json['stage_label'])),
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
        bhk: asString(json['bhk']),
        propertyType: asString(json['property_type']),
        possession: asString(json['possession']),
        dealStatus: asString(json['deal_status']),
        signal: asString(json['signal']),
        openingLine: asString(json['opening_line']),
        aiSummary: asString(json['ai_summary']),
        tags: asStrings(json['tags']),
        fieldGroups:
            asMaps(json['field_groups']).map(LeadFieldGroup.fromJson).toList(),
        people: asMaps(json['people']).map(LeadPerson.fromJson).toList(),
        createdAt: DateTime.tryParse(asString(json['created_at'])),
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

  /// The requirement, as structured columns rather than prose in `notes`.
  final String bhk;
  final String propertyType;
  final String possession;

  /// Open · won · lost, independent of the pipeline stage.
  final String dealStatus;

  /// Private to the owning rep, and redacted by the server for everyone else —
  /// [notesArePrivate] is true when that has happened.
  final String signal;
  final String openingLine;

  /// The CRM's own summary of this lead, where one has been generated.
  final String aiSummary;
  final List<String> tags;

  /// Every recorded field, grouped and labelled by the server. Empty on a
  /// board summary — the board sends the small projection — so a page that
  /// renders these must have a fallback for the fields it already knows.
  final List<LeadFieldGroup> fieldGroups;

  /// The other people around this deal, with their stance.
  final List<LeadPerson> people;

  final DateTime? createdAt;


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
  const PipelineBoard({
    required this.stats,
    required this.leads,
    required this.stages,
  });

  factory PipelineBoard.fromJson(Map<String, dynamic> json) => PipelineBoard(
        stats: PipelineStats.fromJson(asMap(json['stats'])),
        leads: asMaps(json['leads']).map(Lead.fromJson).toList(),
        stages: asMaps(json['stages']).map(Stage.fromJson).toList(),
      );

  static const PipelineBoard empty = PipelineBoard(
    stats: PipelineStats.empty,
    leads: <Lead>[],
    stages: <Stage>[],
  );

  final PipelineStats stats;
  final List<Lead> leads;

  /// The tenant's stage list, in board order, as the server defines it.
  final List<Stage> stages;

  /// Stages worth showing a chip for: the open ones, plus any closed stage
  /// that actually has leads in it. A pipeline of nine leads should not carry
  /// four empty chips for stages this org never uses.
  List<Stage> get visibleStages => stages
      .where((Stage s) => !s.isClosed || countIn(s) > 0)
      .toList();

  List<Lead> inStage(Stage stage) =>
      leads.where((Lead l) => l.stage == stage).toList();

  int countIn(Stage stage) => leads.where((Lead l) => l.stage == stage).length;

  @override
  List<Object?> get props => <Object?>[stats, leads, stages];
}
