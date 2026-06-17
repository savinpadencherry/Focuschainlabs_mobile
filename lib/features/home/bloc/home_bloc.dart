import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/activity.dart';
import '../../../core/models/capture.dart';
import '../../../core/models/meeting.dart';
import '../../../core/repository/capture_repository.dart';
import '../../../core/repository/meeting_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

/// Aggregates the lightweight home surface (F10): today's meetings, pending
/// captures and recent updates, loaded together so the screen renders in one
/// pass.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required MeetingRepository meetingRepository,
    required CaptureRepository captureRepository,
  })  : _meetings = meetingRepository,
        _captures = captureRepository,
        super(const HomeState()) {
    on<HomeLoaded>(_onLoaded);
  }

  final MeetingRepository _meetings;
  final CaptureRepository _captures;

  Future<void> _onLoaded(HomeLoaded event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final List<Meeting> meetings = await _meetings.today();
      final List<Capture> pending = await _captures.pendingCaptures();
      final List<ActivityEntry> activity = await _captures.activity();
      emit(state.copyWith(
        status: HomeStatus.ready,
        meetings: meetings,
        pending: pending,
        activity: activity,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: HomeStatus.failure,
        message: error.toString(),
      ));
    }
  }
}
