import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/meeting.dart';
import '../../../core/repository/meeting_repository.dart';

part 'meetings_event.dart';
part 'meetings_state.dart';

/// Lists the day's meetings and flags those awaiting capture (F3).
class MeetingsBloc extends Bloc<MeetingsEvent, MeetingsState> {
  MeetingsBloc({required MeetingRepository meetingRepository})
      : _meetings = meetingRepository,
        super(const MeetingsState()) {
    on<MeetingsRequested>(_onRequested);
  }

  final MeetingRepository _meetings;

  Future<void> _onRequested(
    MeetingsRequested event,
    Emitter<MeetingsState> emit,
  ) async {
    emit(state.copyWith(status: MeetingsStatus.loading));
    try {
      final List<Meeting> meetings = await _meetings.today();
      emit(state.copyWith(status: MeetingsStatus.ready, meetings: meetings));
    } catch (error) {
      emit(state.copyWith(
        status: MeetingsStatus.failure,
        message: error.toString(),
      ));
    }
  }
}
