import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/get.dart';
import '../../../core/models/capture.dart';
import '../../../core/repository/capture_repository.dart';
import '../../../core/services/navigator_service.dart';
import '../../../core/utils/responsive.dart';
import '../bloc/capture_flow_bloc.dart';
import 'widgets/processing_panel.dart';
import 'widgets/recording_panel.dart';
import 'widgets/review_panel.dart';
import 'widgets/written_panel.dart';

/// The capture flow screen (spec §6.1 / §6.2). A single scaffold whose body
/// swaps between record → process → review → written, so the whole "speak,
/// glance, confirm" loop happens in one place.
class CaptureView extends StatelessWidget {
  const CaptureView({super.key});

  /// Opens the capture flow, optionally pre-filled for a pending [source]
  /// capture (post-meeting). Returns when the user closes the screen.
  static Future<void> open(BuildContext context, {Capture? source}) {
    return Navigator.of(context).push<void>(
      AppPageRoute<void>(
        BlocProvider<CaptureFlowBloc>(
          create: (_) => CaptureFlowBloc(
            captureRepository: app<CaptureRepository>(),
            source: source,
          ),
          child: const CaptureView(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture update'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: ContentBounds(
          maxWidth: Breakpoints.readableMaxWidth,
          child: BlocConsumer<CaptureFlowBloc, CaptureFlowState>(
            listenWhen: (CaptureFlowState p, CaptureFlowState c) =>
                p.status != c.status,
            listener: _onStatusChange,
            builder: (BuildContext context, CaptureFlowState state) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                child: KeyedSubtree(
                  key: ValueKey<CaptureFlowStatus>(_panelKey(state.status)),
                  child: _panelFor(context, state),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onStatusChange(BuildContext context, CaptureFlowState state) {
    if (state.status == CaptureFlowStatus.undone) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Update reverted.')));
      Navigator.of(context).maybePop();
    }
  }

  // Collapse statuses into the panel they render, so AnimatedSwitcher only
  // rebuilds on real panel changes.
  CaptureFlowStatus _panelKey(CaptureFlowStatus status) {
    switch (status) {
      case CaptureFlowStatus.idle:
      case CaptureFlowStatus.recording:
      case CaptureFlowStatus.error:
        return CaptureFlowStatus.idle;
      case CaptureFlowStatus.transcribing:
      case CaptureFlowStatus.extracting:
      case CaptureFlowStatus.writing:
        return CaptureFlowStatus.writing;
      case CaptureFlowStatus.review:
        return CaptureFlowStatus.review;
      case CaptureFlowStatus.written:
      case CaptureFlowStatus.undone:
        return CaptureFlowStatus.written;
    }
  }

  Widget _panelFor(BuildContext context, CaptureFlowState state) {
    switch (state.status) {
      case CaptureFlowStatus.review:
        return ReviewPanel(state: state);
      case CaptureFlowStatus.written:
      case CaptureFlowStatus.undone:
        return WrittenPanel(state: state);
      case CaptureFlowStatus.transcribing:
      case CaptureFlowStatus.extracting:
      case CaptureFlowStatus.writing:
        return ProcessingPanel(status: state.status);
      case CaptureFlowStatus.idle:
      case CaptureFlowStatus.recording:
      case CaptureFlowStatus.error:
        return RecordingPanel(state: state);
    }
  }
}
