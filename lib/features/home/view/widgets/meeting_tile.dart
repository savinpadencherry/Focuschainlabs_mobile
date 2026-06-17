import 'package:flutter/material.dart';

import '../../../../core/models/meeting.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';

/// Compact meeting row used on the home dashboard and meetings list.
class MeetingTile extends StatelessWidget {
  const MeetingTile({super.key, required this.meeting, this.onTap});

  final Meeting meeting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool awaiting = meeting.awaitingCapture;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          _TimeBadge(meeting: meeting),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  meeting.title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${meeting.platform} · ${meeting.durationMinutes} min',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (awaiting) ...<Widget>[
                  const SizedBox(height: 8),
                  _AwaitingBadge(),
                ],
              ],
            ),
          ),
          Icon(
            awaiting ? Icons.mic_rounded : Icons.videocam_outlined,
            color: awaiting ? AppColors.accent : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  const _TimeBadge({required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    final List<String> parts = Formatters.time(meeting.start).split(' ');
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: <Widget>[
          Text(
            parts.first,
            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
          if (parts.length > 1)
            Text(
              parts[1],
              style: const TextStyle(fontSize: 11, color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}

class _AwaitingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: const Text(
        'Awaiting capture',
        style: TextStyle(
          color: Color(0xFFB45309),
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
