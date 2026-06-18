import 'package:equatable/equatable.dart';

import 'enums.dart';

/// One extracted task (spec §8 `action_items[]`).
class ActionItem extends Equatable {
  const ActionItem({
    required this.title,
    this.due,
    this.owner,
    this.selected = true,
  });

  final String title;
  final DateTime? due;
  final String? owner;

  /// Whether the user wants this item pushed to the task tool (F6: deselect).
  final bool selected;

  ActionItem copyWith({String? title, DateTime? due, String? owner, bool? selected}) =>
      ActionItem(
        title: title ?? this.title,
        due: due ?? this.due,
        owner: owner ?? this.owner,
        selected: selected ?? this.selected,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'due': due?.toIso8601String(),
        'owner': owner,
      };

  factory ActionItem.fromJson(Map<String, dynamic> json) => ActionItem(
        title: json['title'] as String? ?? '',
        due: _parseDate(json['due']),
        owner: json['owner'] as String?,
      );

  @override
  List<Object?> get props => <Object?>[title, due, owner, selected];
}

/// The structured record the Claude API must return for F2/F4 (spec §8).
///
/// Mirrors the JSON-only contract exactly. Missing data is `null`, never
/// invented; [isValid] guards against malformed output being written.
class Extraction extends Equatable {
  const Extraction({
    required this.client,
    required this.updateType,
    required this.summary,
    required this.sentiment,
    this.destination = 'crm',
    this.dealStageChange,
    this.nextSteps = const <String>[],
    this.actionItems = const <ActionItem>[],
    this.followUpDate,
    this.notes,
  });

  final String client;
  final UpdateType updateType;
  final String summary;
  final Sentiment sentiment;

  /// Where the AI router decided this belongs: `crm` (record a lead/update) or
  /// `trello` (a task to do). Drives the post-confirm fan-out and webview.
  final String destination;
  final String? dealStageChange;
  final List<String> nextSteps;
  final List<ActionItem> actionItems;
  final DateTime? followUpDate;
  final String? notes;

  /// Rejects malformed extractions before any write (F4 acceptance criteria).
  bool get isValid => client.trim().isNotEmpty && summary.trim().isNotEmpty;

  bool get routesToTrello => destination == 'trello';

  Extraction copyWith({
    String? client,
    UpdateType? updateType,
    String? summary,
    Sentiment? sentiment,
    String? destination,
    String? dealStageChange,
    List<String>? nextSteps,
    List<ActionItem>? actionItems,
    DateTime? followUpDate,
    String? notes,
  }) =>
      Extraction(
        client: client ?? this.client,
        updateType: updateType ?? this.updateType,
        summary: summary ?? this.summary,
        sentiment: sentiment ?? this.sentiment,
        destination: destination ?? this.destination,
        dealStageChange: dealStageChange ?? this.dealStageChange,
        nextSteps: nextSteps ?? this.nextSteps,
        actionItems: actionItems ?? this.actionItems,
        followUpDate: followUpDate ?? this.followUpDate,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'client': client,
        'update_type': updateType.wire,
        'summary': summary,
        'sentiment': sentiment.wire,
        'destination': destination,
        'deal_stage_change': dealStageChange,
        'next_steps': nextSteps,
        'action_items': actionItems.map((ActionItem a) => a.toJson()).toList(),
        'follow_up_date': followUpDate?.toIso8601String(),
        'notes': notes,
      };

  factory Extraction.fromJson(Map<String, dynamic> json) => Extraction(
        client: json['client'] as String? ?? '',
        updateType: UpdateTypeX.fromWire(json['update_type'] as String? ?? 'comment'),
        summary: json['summary'] as String? ?? '',
        sentiment: SentimentX.fromWire(json['sentiment'] as String? ?? 'neutral'),
        destination: (json['destination'] as String?) == 'trello' ? 'trello' : 'crm',
        dealStageChange: json['deal_stage_change'] as String?,
        nextSteps: (json['next_steps'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => e.toString())
            .toList(),
        actionItems: (json['action_items'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(ActionItem.fromJson)
            .toList(),
        followUpDate: _parseDate(json['follow_up_date']),
        notes: json['notes'] as String?,
      );

  @override
  List<Object?> get props => <Object?>[
        client,
        updateType,
        summary,
        sentiment,
        destination,
        dealStageChange,
        nextSteps,
        actionItems,
        followUpDate,
        notes,
      ];
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
