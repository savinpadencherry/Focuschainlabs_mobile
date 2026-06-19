part of 'capture_flow_bloc.dart';

sealed class CaptureFlowEvent extends Equatable {
  const CaptureFlowEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// The composed note (typed or transcribed) submitted to Rex for extraction.
final class CaptureManualSubmitted extends CaptureFlowEvent {
  const CaptureManualSubmitted(this.transcript);

  final String transcript;

  @override
  List<Object?> get props => <Object?>[transcript];
}

/// Inline edits to the extracted record during review.
final class CaptureExtractionChanged extends CaptureFlowEvent {
  const CaptureExtractionChanged(this.extraction);

  final Extraction extraction;

  @override
  List<Object?> get props => <Object?>[extraction];
}

final class CaptureActionItemToggled extends CaptureFlowEvent {
  const CaptureActionItemToggled(this.index);

  final int index;

  @override
  List<Object?> get props => <Object?>[index];
}

final class CaptureConfirmed extends CaptureFlowEvent {
  const CaptureConfirmed();
}

final class CaptureUndoRequested extends CaptureFlowEvent {
  const CaptureUndoRequested();
}

final class CaptureReset extends CaptureFlowEvent {
  const CaptureReset();
}
