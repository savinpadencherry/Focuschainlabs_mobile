import 'package:flutter/material.dart';

import '../../../../core/models/activity.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';

/// A recent-update row for the home activity feed. Surfaces partial-failure
/// state (F5) so a failed task-tool write is visible and retryable.
class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.entry});

  final ActivityEntry entry;

  IconData get _icon => switch (entry.updateType) {
        UpdateType.comment => Icons.chat_bubble_outline_rounded,
        UpdateType.interaction => Icons.handshake_outlined,
        UpdateType.stageChange => Icons.trending_up_rounded,
        UpdateType.followUp => Icons.event_available_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${entry.clientName} · ${entry.updateType.label}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                if (entry.hasFailure) ...<Widget>[
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.error_outline_rounded,
                          size: 14, color: AppColors.atRisk),
                      const SizedBox(width: 4),
                      Text(
                        'Task tool failed — tap to retry',
                        style: TextStyle(
                          color: AppColors.atRisk,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Text(
            Formatters.relative(entry.timestamp),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
