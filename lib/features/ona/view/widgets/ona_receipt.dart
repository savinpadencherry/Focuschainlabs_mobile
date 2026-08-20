import 'package:flutter/material.dart';

import '../../../../core/models/pipeline.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/crm_chips.dart';
import '../../../pipeline/view/lead_detail_view.dart';

/// What landed in the system, shown after a confirmed write.
///
/// The record *as stored*, not a repeat of what was requested — the two differ
/// exactly when something went wrong, which is the case this tile exists for.
/// A rep should be able to see what happened without leaving the conversation.
class OnaReceipt extends StatelessWidget {
  const OnaReceipt({super.key, required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final LeadActivity? latest =
        lead.activities.isEmpty ? null : lead.activities.first;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.check_circle_rounded,
                  size: 16, color: AppColors.green),
              const SizedBox(width: 6),
              Text(
                'Saved',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.greenDeep,
                    ),
              ),
              const Spacer(),
              StageChip(lead.stage),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lead.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          if (latest != null) ...<Widget>[
            const SizedBox(height: 3),
            Text(
              latest.note.isNotEmpty ? latest.note : latest.label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (lead.nextFollowUp.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            TagChip(
              'Next follow-up ${lead.nextFollowUp}',
              color: AppColors.navy,
              icon: Icons.event_rounded,
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => LeadDetailView.open(context, lead.id),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: const Text('Open the lead'),
            ),
          ),
        ],
      ),
    );
  }
}
