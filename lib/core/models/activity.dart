import 'package:equatable/equatable.dart';

import 'enums.dart';

/// A record of an external write (CRM/task/calendar) for the home "recent
/// updates" feed and the partial-failure surface (F5/F10).
class ActivityEntry extends Equatable {
  const ActivityEntry({
    required this.id,
    required this.clientName,
    required this.description,
    required this.updateType,
    required this.timestamp,
    this.crmOk = true,
    this.taskOk = true,
    this.calendarOk = true,
  });

  final String id;
  final String clientName;
  final String description;
  final UpdateType updateType;
  final DateTime timestamp;

  // Per-destination outcome so partial failures are surfaced and retryable.
  final bool crmOk;
  final bool taskOk;
  final bool calendarOk;

  bool get hasFailure => !crmOk || !taskOk || !calendarOk;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'clientName': clientName,
        'description': description,
        'updateType': updateType.wire,
        'timestamp': timestamp.toIso8601String(),
        'crmOk': crmOk,
        'taskOk': taskOk,
        'calendarOk': calendarOk,
      };

  factory ActivityEntry.fromJson(Map<String, dynamic> json) => ActivityEntry(
        id: json['id'] as String,
        clientName: json['clientName'] as String,
        description: json['description'] as String,
        updateType: UpdateTypeX.fromWire(json['updateType'] as String? ?? 'comment'),
        timestamp: DateTime.parse(json['timestamp'] as String),
        crmOk: json['crmOk'] as bool? ?? true,
        taskOk: json['taskOk'] as bool? ?? true,
        calendarOk: json['calendarOk'] as bool? ?? true,
      );

  @override
  List<Object?> get props =>
      <Object?>[id, clientName, description, updateType, timestamp];
}

/// A connected (or pending) integration shown on the profile/connections
/// surface (F9/F10).
class Integration extends Equatable {
  const Integration({
    required this.name,
    required this.category,
    required this.status,
    this.detail,
  });

  final String name;
  final String category; // CRM / Calendar / Task / Email
  final ConnectionStatus status;
  final String? detail;

  @override
  List<Object?> get props => <Object?>[name, category, status, detail];
}
