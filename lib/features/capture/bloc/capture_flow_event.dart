part of 'capture_flow_bloc.dart';

sealed class CaptureFlowEvent extends Equatable {
  const CaptureFlowEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class CaptureRecordingStarted extends CaptureFlowEvent {
  const CaptureRecordingStarted();
}

final class CaptureRecordingStopped extends CaptureFlowEvent {
  const CaptureRecordingStopped();
}

/// Typed fallback path (F4: typing is a fallback, never the default).
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
