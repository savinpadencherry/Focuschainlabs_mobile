import 'package:flutter/material.dart';

import '../../core/models/pipeline.dart';
import '../../core/theme/app_colors.dart';

/// One fact about a lead — budget, area, what they want — as a labelled pill.
///
/// Extracted so the Ona answer tile and the lead's own page draw these the
/// same way. They did not: an answer showed budget, area and requirement while
/// opening the same lead from Pipeline showed a name and little else, so the
/// richer view was the one you reached by accident.
///
/// Only what is on file. These must never fall back to a specimen value — a
/// rep reading a budget off a card that the client never gave is worse than a
/// visible gap.
class LeadFactPills extends StatelessWidget {
  const LeadFactPills({
    super.key,
    required this.facts,
    this.emptyMessage = 'Nothing recorded about what they want yet.',
  });

  /// (icon, value, colour), already filtered to what exists.
  final List<(IconData, String, Color)> facts;
  final String emptyMessage;

  /// The pills an Ona answer row carries. Each answer type uses slightly
  /// different keys for the same thing, hence the fallbacks.
  factory LeadFactPills.fromRow(Map<String, dynamic> row, {Key? key}) {
    final String due = asString(row['follow_up']);
    final String budget = asString(row['budget']).isNotEmpty
        ? asString(row['budget'])
        : asString(row['value_fmt']);
    final String where = asString(row['locality']).isNotEmpty
        ? asString(row['locality'])
        : asString(row['area']);
    final String wants = asString(row['property_type']).isNotEmpty
        ? asString(row['property_type'])
        : asString(row['requirement']);

    return LeadFactPills(
      key: key,
      facts: <(IconData, String, Color)>[
        if (due.isNotEmpty) (Icons.schedule_rounded, due, AppColors.atRisk),
        if (budget.isNotEmpty)
          (Icons.currency_rupee_rounded, budget, AppColors.green),
        if (where.isNotEmpty) (Icons.place_outlined, where, AppColors.iris),
        if (wants.isNotEmpty) (Icons.home_work_outlined, wants, AppColors.inkSoft),
      ],
    );
  }

  /// The same pills for a full [Lead], so the lead's own page shows what its
  /// tile in an answer showed.
  factory LeadFactPills.fromLead(Lead lead, {Key? key}) {
    return LeadFactPills(
      key: key,
      facts: <(IconData, String, Color)>[
        if (lead.followUpDue && lead.nextFollowUp.isNotEmpty)
          (Icons.schedule_rounded, 'Due ${lead.nextFollowUp}', AppColors.atRisk),
        if (lead.moneyLabel.isNotEmpty)
          (Icons.currency_rupee_rounded, lead.moneyLabel, AppColors.green),
        if (lead.locality.isNotEmpty)
          (Icons.place_outlined, lead.locality, AppColors.iris),
        if (lead.requirement.isNotEmpty)
          (Icons.home_work_outlined, lead.requirement, AppColors.inkSoft),
        if (lead.source.isNotEmpty)
          (Icons.input_rounded, lead.source, AppColors.inkMuted),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (facts.isEmpty) {
      return Text(
        emptyMessage,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(fontStyle: FontStyle.italic),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        for (final (IconData icon, String value, Color c) in facts)
          _Pill(icon: icon, value: value, colour: c),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.value, required this.colour});

  final IconData icon;
  final String value;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: colour.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: colour),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: colour,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
