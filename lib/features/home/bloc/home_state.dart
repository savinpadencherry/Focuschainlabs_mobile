part of 'home_bloc.dart';

enum HomeStatus { initial, loading, ready, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.meetings = const <Meeting>[],
    this.pending = const <Capture>[],
    this.activity = const <ActivityEntry>[],
    this.message,
  });

  final HomeStatus status;
  final List<Meeting> meetings;
  final List<Capture> pending;
  final List<ActivityEntry> activity;
  final String? message;

  /// Next upcoming meeting (or the most recent one if all have passed).
  Meeting? get nextMeeting {
    final List<Meeting> upcoming =
        meetings.where((Meeting m) => m.isUpcoming).toList();
    if (upcoming.isNotEmpty) return upcoming.first;
    return meetings.isEmpty ? null : meetings.last;
  }

  HomeState copyWith({
    HomeStatus? status,
    List<Meeting>? meetings,
    List<Capture>? pending,
    List<ActivityEntry>? activity,
    String? message,
  }) =>
      HomeState(
        status: status ?? this.status,
        meetings: meetings ?? this.meetings,
        pending: pending ?? this.pending,
        activity: activity ?? this.activity,
        message: message ?? this.message,
      );

  @override
  List<Object?> get props =>
      <Object?>[status, meetings, pending, activity, message];
}
