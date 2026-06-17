import 'package:equatable/equatable.dart';

/// A calendar meeting sourced from the org's calendar (spec §8 `meeting`).
///
/// `captureEligible` reflects the F3 rule that only external/tagged meetings
/// prompt a post-meeting capture — internal stand-ups do not.
class Meeting extends Equatable {
  const Meeting({
    required this.id,
    required this.title,
    required this.clientName,
    required this.start,
    required this.durationMinutes,
    required this.platform,
    this.attendees = const <String>[],
    this.captureEligible = true,
    this.captured = false,
  });

  final String id;
  final String title;
  final String clientName;
  final DateTime start;
  final int durationMinutes;
  final String platform;
  final List<String> attendees;
  final bool captureEligible;
  final bool captured;

  DateTime get end => start.add(Duration(minutes: durationMinutes));
  bool get hasEnded => DateTime.now().isAfter(end);
  bool get isUpcoming => DateTime.now().isBefore(start);

  /// True when the meeting just ended and is awaiting a capture prompt (F3).
  bool get awaitingCapture => hasEnded && captureEligible && !captured;

  Meeting copyWith({bool? captured}) => Meeting(
        id: id,
        title: title,
        clientName: clientName,
        start: start,
        durationMinutes: durationMinutes,
        platform: platform,
        attendees: attendees,
        captureEligible: captureEligible,
        captured: captured ?? this.captured,
      );

  @override
  List<Object?> get props => <Object?>[id, title, clientName, start, captured];
}
