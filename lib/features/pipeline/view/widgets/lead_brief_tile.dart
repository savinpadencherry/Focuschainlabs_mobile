import 'package:flutter/material.dart';

import '../../../../core/models/lead_chat.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// The card a lead opens with: stage, what they want, what has been sent,
/// what is open, when you last spoke, what is missing.
///
/// The same tile the web app draws, from the same server-built brief. Rows
/// marked as gaps render in the muted italic the web uses — a blank is a thing
/// to go and fill in, and giving it the same weight as a known fact is how it
/// gets read as one.
class LeadBriefTile extends StatelessWidget {
  const LeadBriefTile({super.key, required this.brief});

  final LeadBrief brief;

  @override
  Widget build(BuildContext context) {
    if (brief.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(width: 3, color: AppColors.green),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (brief.stage.isNotEmpty)
                    _Row(
                      label: 'STAGE',
                      value: brief.stage,
                      emphasis: true,
                    ),
                  for (final BriefRow r in brief.rows) ...<Widget>[
                    const SizedBox(height: 9),
                    _Row(label: r.label, value: r.value, gap: r.isGap),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.gap = false,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool gap;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: AppColors.inkMuted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: emphasis ? 15 : 13.5,
              height: 1.35,
              fontWeight: emphasis ? FontWeight.w800 : FontWeight.w500,
              fontStyle: gap ? FontStyle.italic : FontStyle.normal,
              color: gap ? AppColors.inkMuted : AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}
