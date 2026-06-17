part of 'meetings_bloc.dart';

enum MeetingsStatus { initial, loading, ready, failure }

class MeetingsState extends Equatable {
  const MeetingsState({
    this.status = MeetingsStatus.initial,
    this.meetings = const <Meeting>[],
    this.message,
  });

  final MeetingsStatus status;
  final List<Meeting> meetings;
  final String? message;

  MeetingsState copyWith({
    MeetingsStatus? status,
    List<Meeting>? meetings,
    String? message,
  }) =>
      MeetingsState(
        status: status ?? this.status,
        meetings: meetings ?? this.meetings,
        message: message ?? this.message,
      );

  @override
  List<Object?> get props => <Object?>[status, meetings, message];
}
