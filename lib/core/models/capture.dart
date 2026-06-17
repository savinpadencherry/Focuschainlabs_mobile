import 'package:equatable/equatable.dart';

import 'enums.dart';
import 'extraction.dart';

/// Where a capture originated.
enum CaptureSource { conversational, postMeeting }

/// A structured update extracted from a spoken note (spec §8 `capture`).
///
/// Links the raw transcript, the AI [extraction], the source, and the
/// resulting status, so it can be queued (F3 pending list), reviewed (F4),
/// written (F5) and undone (F5 reversibility).
class Capture extends Equatable {
  const Capture({
    required this.id,
    required this.clientName,
    required this.summary,
    required this.createdAt,
    this.transcript,
    this.extraction,
    this.source = CaptureSource.conversational,
    this.status = CaptureStatus.pending,
    this.meetingId,
  });

  final String id;
  final String clientName;
  final String summary;
  final DateTime createdAt;
  final String? transcript;
  final Extraction? extraction;
  final CaptureSource source;
  final CaptureStatus status;
  final String? meetingId;

  bool get isPending => status == CaptureStatus.pending;
  bool get isWritten => status == CaptureStatus.written;

  Capture copyWith({
    String? summary,
    String? transcript,
    Extraction? extraction,
    CaptureStatus? status,
  }) =>
      Capture(
        id: id,
        clientName: clientName,
        summary: summary ?? this.summary,
        createdAt: createdAt,
        transcript: transcript ?? this.transcript,
        extraction: extraction ?? this.extraction,
        source: source,
        status: status ?? this.status,
        meetingId: meetingId,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'clientName': clientName,
        'summary': summary,
        'createdAt': createdAt.toIso8601String(),
        'transcript': transcript,
        'extraction': extraction?.toJson(),
        'source': source.name,
        'status': status.name,
        'meetingId': meetingId,
      };

  factory Capture.fromJson(Map<String, dynamic> json) => Capture(
        id: json['id'] as String,
        clientName: json['clientName'] as String,
        summary: json['summary'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        transcript: json['transcript'] as String?,
        extraction: json['extraction'] == null
            ? null
            : Extraction.fromJson(json['extraction'] as Map<String, dynamic>),
        source: CaptureSource.values.firstWhere(
          (CaptureSource s) => s.name == json['source'],
          orElse: () => CaptureSource.conversational,
        ),
        status: CaptureStatus.values.firstWhere(
          (CaptureStatus s) => s.name == json['status'],
          orElse: () => CaptureStatus.pending,
        ),
        meetingId: json['meetingId'] as String?,
      );

  @override
  List<Object?> get props =>
      <Object?>[id, clientName, summary, createdAt, status, extraction];
}
