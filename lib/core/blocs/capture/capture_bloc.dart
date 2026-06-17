import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/capture.dart';
import '../../repository/capture_repository.dart';

sealed class CaptureEvent extends Equatable {
  const CaptureEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class CaptureRequested extends CaptureEvent {
  const CaptureRequested();
}

sealed class CaptureState extends Equatable {
  const CaptureState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class CaptureInitial extends CaptureState {
  const CaptureInitial();
}

final class CaptureLoading extends CaptureState {
  const CaptureLoading();
}

final class CaptureLoaded extends CaptureState {
  const CaptureLoaded(this.captures);

  final List<Capture> captures;

  @override
  List<Object?> get props => <Object?>[captures];
}

final class CaptureFailure extends CaptureState {
  const CaptureFailure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

class CaptureBloc extends Bloc<CaptureEvent, CaptureState> {
  CaptureBloc({required CaptureRepository captureRepository})
      : _captureRepository = captureRepository,
        super(const CaptureInitial()) {
    on<CaptureRequested>(_onRequested);
  }

  final CaptureRepository _captureRepository;

  Future<void> _onRequested(
    CaptureRequested event,
    Emitter<CaptureState> emit,
  ) async {
    emit(const CaptureLoading());
    try {
      emit(CaptureLoaded(await _captureRepository.fetchPendingCaptures()));
    } catch (error) {
      emit(CaptureFailure(error.toString()));
    }
  }
}
