import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/activity.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../bloc/capture_flow_bloc.dart';

/// Success state: confirms the fan-out write and offers a one-tap undo for a
/// short window (F5 reversibility).
class WrittenPanel extends StatefulWidget {
  const WrittenPanel({super.key, required this.state});

  final CaptureFlowState state;

  @override
  State<WrittenPanel> createState() => _WrittenPanelState();
}

class _WrittenPanelState extends State<WrittenPanel> {
  late int _remaining = AppConstants.undoWindow.inSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ActivityEntry? entry = widget.state.activityEntry;
    final bool canUndo = _remaining > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: <Widget>[
          const Spacer(),
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: AppColors.positive,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          AppSpacing.vGapXl,
          Text(
            'Update written',
            style: Theme.of(context).textTheme.headlineSmall,
          ).animate().fadeIn(delay: 150.ms),
          AppSpacing.vGapSm,
          Text(
            'Saved to the CRM record for ${entry?.clientName ?? 'the client'}, '
            'with tasks and follow-ups routed.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ).animate().fadeIn(delay: 250.ms),
          AppSpacing.vGapXl,
          if (entry != null) _Destinations(entry: entry),
          const Spacer(),
          if (canUndo)
            OutlinedButton.icon(
              onPressed: () =>
                  context.read<CaptureFlowBloc>().add(const CaptureUndoRequested()),
              icon: const Icon(Icons.undo_rounded),
              label: Text('Undo  ·  ${_remaining}s'),
            ),
          AppSpacing.vGapMd,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Destinations extends StatelessWidget {
  const _Destinations({required this.entry});

  final ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _DestinationRow(label: 'CRM record', ok: entry.crmOk),
        _DestinationRow(label: 'Task tool (Trello)', ok: entry.taskOk),
        _DestinationRow(label: 'Calendar follow-up', ok: entry.calendarOk),
      ],
    );
  }
}

class _DestinationRow extends StatelessWidget {
  const _DestinationRow({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Icon(
            ok ? Icons.check_circle_rounded : Icons.error_rounded,
            size: 18,
            color: ok ? AppColors.positive : AppColors.atRisk,
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          if (!ok)
            const Text(
              'Retry',
              style: TextStyle(
                color: AppColors.atRisk,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
