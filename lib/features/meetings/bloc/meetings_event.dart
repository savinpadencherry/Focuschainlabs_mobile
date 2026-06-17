part of 'meetings_bloc.dart';

sealed class MeetingsEvent extends Equatable {
  const MeetingsEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class MeetingsRequested extends MeetingsEvent {
  const MeetingsRequested();
}
