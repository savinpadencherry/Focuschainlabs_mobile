part of 'capture_flow_bloc.dart';

enum CaptureFlowStatus {
  idle,
  transcribing,
  extracting,
  review,
  writing,
  written,
  undone,
  error,
}

class CaptureFlowState extends Equatable {
  const CaptureFlowState({
    this.status = CaptureFlowStatus.idle,
    this.source,
    this.transcript,
    this.extraction,
    this.writtenCapture,
    this.activityEntry,
    this.message,
  });

  final CaptureFlowStatus status;

  /// The pending capture this session is fulfilling, if any (post-meeting).
  final Capture? source;
  final String? transcript;
  final Extraction? extraction;
  final Capture? writtenCapture;
  final ActivityEntry? activityEntry;
  final String? message;

  bool get isBusy =>
      status == CaptureFlowStatus.transcribing ||
      status == CaptureFlowStatus.extracting ||
      status == CaptureFlowStatus.writing;

  bool get isReviewing => status == CaptureFlowStatus.review;
  bool get isWritten => status == CaptureFlowStatus.written;

  CaptureFlowState copyWith({
    CaptureFlowStatus? status,
    Capture? source,
    String? transcript,
    Extraction? extraction,
    Capture? writtenCapture,
    ActivityEntry? activityEntry,
    String? message,
  }) =>
      CaptureFlowState(
        status: status ?? this.status,
        source: source ?? this.source,
        transcript: transcript ?? this.transcript,
        extraction: extraction ?? this.extraction,
        writtenCapture: writtenCapture ?? this.writtenCapture,
        activityEntry: activityEntry ?? this.activityEntry,
        message: message,
      );

  @override
  List<Object?> get props => <Object?>[
        status,
        source,
        transcript,
        extraction,
        writtenCapture,
        activityEntry,
        message,
      ];
}
