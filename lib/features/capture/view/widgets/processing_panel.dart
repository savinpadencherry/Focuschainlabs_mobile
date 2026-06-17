import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../bloc/capture_flow_bloc.dart';

/// Transient state while the note is transcribed, extracted, or written.
class ProcessingPanel extends StatelessWidget {
  const ProcessingPanel({super.key, required this.status});

  final CaptureFlowStatus status;

  String get _label => switch (status) {
        CaptureFlowStatus.transcribing => 'Transcribing your note…',
        CaptureFlowStatus.extracting => 'Rex is structuring the update…',
        CaptureFlowStatus.writing => 'Writing to CRM, tasks & calendar…',
        _ => 'Working…',
      };

  IconData get _icon => switch (status) {
        CaptureFlowStatus.transcribing => Icons.graphic_eq_rounded,
        CaptureFlowStatus.extracting => Icons.auto_awesome_rounded,
        CaptureFlowStatus.writing => Icons.cloud_upload_outlined,
        _ => Icons.hourglass_empty_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.logoGradient),
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(_icon, color: Colors.white, size: 40),
          )
              .animate(onPlay: (AnimationController c) => c.repeat())
              .scaleXY(end: 1.08, duration: 800.ms, curve: Curves.easeInOut)
              .then()
              .scaleXY(end: 1 / 1.08, duration: 800.ms, curve: Curves.easeInOut),
          AppSpacing.vGapXl,
          Text(
            _label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          AppSpacing.vGapMd,
          const SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              minHeight: 4,
              backgroundColor: AppColors.surfaceMuted,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
