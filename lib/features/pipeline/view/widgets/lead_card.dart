import 'package:flutter/material.dart';

import '../../../../core/models/pipeline.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/crm_chips.dart';
import '../../../../shared/widgets/lead_facts.dart';

/// One lead on the board.
///
/// The left edge is a stage-coloured rail rather than a badge in the corner:
/// scanning a column of twenty leads, the eye follows the rail and never has
/// to read the word.
class LeadCard extends StatelessWidget {
  const LeadCard({super.key, required this.lead, required this.onTap});

  final Lead lead;
  final VoidCallback onTap;

  /// What this lead is after, in the order a rep scans for it.
  ///
  /// The configuration is on the board because "3 BHK" is the fact that
  /// decides whether a property is worth sending — it was on the record and
  /// on the web app's card, and reachable on the phone only by opening the
  /// lead and reading the requirement sentence.
  List<(IconData, String, Color)> get _wants => <(IconData, String, Color)>[
        if (lead.bhk.isNotEmpty)
          (Icons.king_bed_outlined, lead.bhk, AppColors.green),
        if (lead.propertyType.isNotEmpty)
          (Icons.apartment_rounded, lead.propertyType, AppColors.inkSoft),
        if (lead.locality.isNotEmpty)
          (Icons.place_outlined, lead.locality, AppColors.iris),
        // Only when nothing structured says the same thing — the requirement
        // sentence usually repeats the configuration and the area back.
        if (lead.requirement.isNotEmpty && lead.bhk.isEmpty)
          (Icons.home_work_outlined, lead.requirement, AppColors.inkSoft),
      ];

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: stageColor(lead.stage),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppSpacing.radiusLg),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 13, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            lead.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (lead.moneyLabel.isNotEmpty) ...<Widget>[
                          const SizedBox(width: 8),
                          Text(
                            lead.moneyLabel,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (lead.subtitle.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        lead.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 9),
                    ChipRow(
                      children: <Widget>[
                        StageChip(lead.stage),
                        if (lead.needsAttention) RiskChip(lead),
                      ],
                    ),
                    if (_wants.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      LeadFactPills(facts: _wants),
                    ],
                    const SizedBox(height: 9),
                    Row(
                      children: <Widget>[
                        _Score(score: lead.score),
                        const Spacer(),
                        Text(
                          _idleLabel(lead.daysSinceActivity),
                          style: text.bodySmall?.copyWith(
                            color: lead.daysSinceActivity > 14
                                ? AppColors.atRisk
                                : AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _idleLabel(int days) {
    if (days <= 0) return 'Active today';
    if (days == 1) return '1 day quiet';
    return '$days days quiet';
  }
}

/// The score as a bar rather than a number alone — 58 means nothing on its own,
/// but a bar filled just past halfway is legible at a glance.
class _Score extends StatelessWidget {
  const _Score({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final double fraction = (score.clamp(0, 100)) / 100;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 46,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(3),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fraction == 0 ? 0.02 : fraction,
            child: Container(
              decoration: BoxDecoration(
                color: score >= 60
                    ? AppColors.green
                    : (score >= 35 ? AppColors.atRisk : AppColors.inkMuted),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          '$score',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.inkSoft,
          ),
        ),
      ],
    );
  }
}
