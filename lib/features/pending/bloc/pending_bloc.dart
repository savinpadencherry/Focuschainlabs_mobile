import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/capture.dart';
import '../../../core/repository/capture_repository.dart';

part 'pending_event.dart';
part 'pending_state.dart';

/// Backs the 'Pending capture' list (F3: ignored prompts move here, never
/// lost).
class PendingBloc extends Bloc<PendingEvent, PendingState> {
  PendingBloc({required CaptureRepository captureRepository})
      : _captures = captureRepository,
        super(const PendingState()) {
    on<PendingRequested>(_onRequested);
  }

  final CaptureRepository _captures;

  Future<void> _onRequested(
    PendingRequested event,
    Emitter<PendingState> emit,
  ) async {
    emit(state.copyWith(status: PendingStatus.loading));
    try {
      final List<Capture> captures = await _captures.pendingCaptures();
      emit(state.copyWith(status: PendingStatus.ready, captures: captures));
    } catch (error) {
      emit(state.copyWith(
        status: PendingStatus.failure,
        message: error.toString(),
      ));
    }
  }
}
