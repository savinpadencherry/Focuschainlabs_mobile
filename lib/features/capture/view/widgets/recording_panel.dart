import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/pulsing_mic.dart';
import '../../bloc/capture_flow_bloc.dart';
import 'type_instead_sheet.dart';

/// The idle/recording state: speak a note, with a typed fallback (F4).
class RecordingPanel extends StatefulWidget {
  const RecordingPanel({super.key, required this.state});

  final CaptureFlowState state;

  @override
  State<RecordingPanel> createState() => _RecordingPanelState();
}

class _RecordingPanelState extends State<RecordingPanel> {
  Timer? _timer;
  int _seconds = 0;

  bool get _recording => widget.state.status == CaptureFlowStatus.recording;

  void _toggle() {
    final CaptureFlowBloc bloc = context.read<CaptureFlowBloc>();
    if (_recording) {
      _timer?.cancel();
      bloc.add(const CaptureRecordingStopped());
    } else {
      setState(() => _seconds = 0);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _seconds++);
      });
      bloc.add(const CaptureRecordingStarted());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _elapsed =>
      '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final String? client = widget.state.source?.clientName;
    final bool isError = widget.state.status == CaptureFlowStatus.error;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: <Widget>[
          if (client != null) _ContextChip(client: client),
          const Spacer(),
          Text(
            _recording ? 'Listening…' : 'Tap to talk',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          AppSpacing.vGapSm,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              isError
                  ? (widget.state.message ?? 'Something went wrong.')
                  : AppStrings.captureHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isError ? AppColors.negative : AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
          const Spacer(),
          PulsingMic(recording: _recording, onTap: _toggle),
          AppSpacing.vGapLg,
          AnimatedOpacity(
            opacity: _recording ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Text(
              _elapsed,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                color: AppColors.negative,
              ),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => TypeInsteadSheet.show(context),
            icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
            label: const Text(AppStrings.typeInstead),
          ),
        ],
      ),
    );
  }
}

class _ContextChip extends StatelessWidget {
  const _ContextChip({required this.client});

  final String client;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.event_note_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'Capturing for $client',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
