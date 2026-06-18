import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/activity.dart';
import '../../../core/models/capture.dart';
import '../../../core/models/extraction.dart';
import '../../../core/repository/capture_repository.dart';

part 'capture_flow_event.dart';
part 'capture_flow_state.dart';

/// Orchestrates a single capture session end-to-end (spec §6.1 / §6.2):
/// compose → extract → review/edit → confirm/write → undo. Voice capture is
/// handled in [RecordingPanel]; this bloc receives the final transcript via
/// [CaptureManualSubmitted].
class CaptureFlowBloc extends Bloc<CaptureFlowEvent, CaptureFlowState> {
  CaptureFlowBloc({
    required CaptureRepository captureRepository,
    Capture? source,
  })  : _captures = captureRepository,
        super(CaptureFlowState(source: source)) {
    on<CaptureManualSubmitted>(_onManualSubmitted);
    on<CaptureExtractionChanged>(_onExtractionChanged);
    on<CaptureActionItemToggled>(_onActionItemToggled);
    on<CaptureConfirmed>(_onConfirmed);
    on<CaptureUndoRequested>(_onUndoRequested);
    on<CaptureReset>(_onReset);
  }

  final CaptureRepository _captures;

  Future<void> _onManualSubmitted(
    CaptureManualSubmitted event,
    Emitter<CaptureFlowState> emit,
  ) async {
    if (event.transcript.trim().isEmpty || state.isBusy) return;
    await _processTranscript(event.transcript, emit);
  }

  /// Shared extraction step: transcript → validated [Extraction] → review.
  Future<void> _processTranscript(
    String transcript,
    Emitter<CaptureFlowState> emit,
  ) async {
    emit(state.copyWith(
      status: CaptureFlowStatus.extracting,
      transcript: transcript,
      message: null,
    ));
    try {
      final Extraction extraction = await _captures.draft(transcript);
      emit(state.copyWith(
        status: CaptureFlowStatus.review,
        extraction: extraction,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: CaptureFlowStatus.error,
        message: error is FormatException
            ? error.message
            : 'Could not understand that note — please try again.',
      ));
    }
  }

  void _onExtractionChanged(
    CaptureExtractionChanged event,
    Emitter<CaptureFlowState> emit,
  ) {
    emit(state.copyWith(extraction: event.extraction));
  }

  void _onActionItemToggled(
    CaptureActionItemToggled event,
    Emitter<CaptureFlowState> emit,
  ) {
    final Extraction? extraction = state.extraction;
    if (extraction == null) return;
    final List<ActionItem> items = List<ActionItem>.of(extraction.actionItems);
    if (event.index < 0 || event.index >= items.length) return;
    items[event.index] =
        items[event.index].copyWith(selected: !items[event.index].selected);
    emit(state.copyWith(extraction: extraction.copyWith(actionItems: items)));
  }

  Future<void> _onConfirmed(
    CaptureConfirmed event,
    Emitter<CaptureFlowState> emit,
  ) async {
    final Extraction? extraction = state.extraction;
    if (extraction == null || !extraction.isValid || state.isBusy) return;
    emit(state.copyWith(status: CaptureFlowStatus.writing));

    final Capture capture = state.source ??
        Capture(
          id: 'cap-${DateTime.now().microsecondsSinceEpoch}',
          clientName: extraction.client,
          summary: extraction.summary,
          createdAt: DateTime.now(),
          transcript: state.transcript,
        );

    try {
      final ActivityEntry entry = await _captures.confirm(
        capture: capture,
        extraction: extraction,
      );
      emit(state.copyWith(
        status: CaptureFlowStatus.written,
        writtenCapture: capture,
        activityEntry: entry,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: CaptureFlowStatus.review,
        message: error is FormatException
            ? error.message
            : 'Write failed — please try again.',
      ));
    }
  }

  Future<void> _onUndoRequested(
    CaptureUndoRequested event,
    Emitter<CaptureFlowState> emit,
  ) async {
    final ActivityEntry? entry = state.activityEntry;
    if (entry == null) return;
    await _captures.undo(entry, captureId: state.writtenCapture?.id);
    emit(state.copyWith(status: CaptureFlowStatus.undone));
  }

  void _onReset(CaptureReset event, Emitter<CaptureFlowState> emit) {
    emit(CaptureFlowState(source: state.source));
  }
}
