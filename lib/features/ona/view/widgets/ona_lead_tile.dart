import 'package:flutter/material.dart';

import '../../../../core/models/pipeline.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../pipeline/view/lead_chat_view.dart';
import '../../../pipeline/view/lead_detail_view.dart';

/// The one way a lead appears in an Ona answer.
///
/// Ported from the web app's `_render_universal_lead_tile`, and for the reason
/// that change records: "what follow-ups are due?" used to answer with plain
/// rows — a name and a reason — while every other answer drew a tile with the
/// stage, budget and requirement. Same lead, two presentations, and only one
/// of them could be opened. Focus, risk, lead and tasks all render through
/// this.
///
/// The meta pills show **only what is on file**. They used to fall back to a
/// specimen budget and area, so a lead with nothing recorded displayed a
/// furnished requirement and a rep could read a budget off the card that the
/// client had never given. An absent field shows no pill, which is the truth
/// and is visibly a gap to fill.
class OnaLeadTile extends StatelessWidget {
  const OnaLeadTile({super.key, required this.row, this.rank});

  /// A row from any Ona answer: focus, risk, lead or tasks. They carry
  /// different subsets of the same field names, which is why every read below
  /// is a fallback chain rather than a single key.
  final Map<String, dynamic> row;
  final int? rank;

  String get _id => asString(row['contact_id']).isNotEmpty
      ? asString(row['contact_id'])
      : asString(row['id']);

  String get _name {
    for (final String key in <String>['contact_name', 'name', 'company']) {
      final String v = asString(row[key]);
      if (v.isNotEmpty) return v;
    }
    return 'Lead';
  }

  String get _stage {
    final String raw = asString(row['stage']);
    if (raw.isEmpty) return '';
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .where((String w) => w.isNotEmpty)
        .map((String w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  /// Budget, location, requirement — each from whichever key this answer used.
  List<(IconData, String, Color)> get _facts {
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

    return <(IconData, String, Color)>[
      if (due.isNotEmpty) (Icons.schedule_rounded, due, AppColors.atRisk),
      if (budget.isNotEmpty)
        (Icons.currency_rupee_rounded, budget, AppColors.green),
      if (where.isNotEmpty) (Icons.place_outlined, where, AppColors.iris),
      if (wants.isNotEmpty) (Icons.home_work_outlined, wants, AppColors.inkSoft),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<(IconData, String, Color)> facts = _facts;
    final int? score = row['score'] is num ? (row['score'] as num).toInt() : null;
    final int? idle =
        row['days_idle'] is num ? (row['days_idle'] as num).toInt() : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  rank != null ? '#$rank  $_name' : _name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              if (_stage.isNotEmpty || score != null)
                _StatusPill(stage: _stage, score: score, idle: idle),
            ],
          ),
          const SizedBox(height: 8),
          if (facts.isEmpty)
            Text(
              'Nothing recorded about what they want yet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final (IconData icon, String value, Color c) in facts)
                  _Fact(icon: icon, value: value, colour: c),
              ],
            ),
          if (_id.isNotEmpty) ...<Widget>[
            const SizedBox(height: 11),
            // Two destinations, because they answer different questions: the
            // record itself, and the conversation about it. Sending someone to
            // the chat when they wanted the file is a detour they have to
            // notice and undo.
            Row(
              children: <Widget>[
                Expanded(
                  child: _TileButton(
                    label: 'Open lead',
                    icon: Icons.badge_outlined,
                    onTap: () => LeadDetailView.open(context, _id),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TileButton(
                    label: 'Lead chat',
                    icon: Icons.forum_outlined,
                    primary: true,
                    onTap: () => LeadChatView.open(context, _id),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.stage, this.score, this.idle});

  final String stage;
  final int? score;
  final int? idle;

  @override
  Widget build(BuildContext context) {
    final List<String> parts = <String>[
      if (stage.isNotEmpty) stage,
      if (score != null) '$score/100',
      if (idle != null && idle! > 0) '${idle}d idle',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        parts.join(' · '),
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.inkSoft,
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.value, required this.colour});

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

class _TileButton extends StatelessWidget {
  const _TileButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final Color colour = primary ? AppColors.iris : AppColors.inkSoft;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: primary
              ? AppColors.iris.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: colour.withValues(alpha: 0.32)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 15, color: colour),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: colour,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
