import 'package:flutter/material.dart';

import '../../core/models/pipeline.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Colours for the pipeline stages.
///
/// A ramp that deepens towards iris as a lead advances, so the board reads as
/// progress rather than as escalating alarm, with green and grey reserved for
/// the two terminal outcomes. Keyed by name rather than by enum because the
/// stage list comes from the server — a tenant that adds a stage gets the
/// fallback rather than a crash.
const Map<String, Color> _stageColors = <String, Color>{
  'new': Color(0xFF9A93B8),
  'contacted': Color(0xFF8779C9),
  'interested': Color(0xFF7350D0),
  'site_visits': Color(0xFF6340BE),
  'offer': Color(0xFF5B3EA8),
  'negotiation': Color(0xFF4A3391),
  'agreement': Color(0xFF3D2A78),
  'closed': AppColors.green,
  'won': AppColors.green,
  'lost': AppColors.inkMuted,
};

Color stageColor(Stage stage) =>
    _stageColors[stage.key] ?? AppColors.inkMuted;

Color riskColor(RiskLevel risk) => switch (risk) {
      RiskLevel.healthy => AppColors.green,
      RiskLevel.needsAttention => AppColors.atRisk,
      RiskLevel.atRisk => AppColors.negative,
    };

/// A small filled pill. The one chip primitive, so every surface's chips agree
/// about height, radius and letter spacing.
class TagChip extends StatelessWidget {
  const TagChip(
    this.label, {
    super.key,
    this.color = AppColors.inkSoft,
    this.filled = true,
    this.icon,
    this.onTap,
    this.onRemove,
  });

  final String label;
  final Color color;
  final bool filled;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final Widget body = Container(
      padding: EdgeInsets.fromLTRB(
        icon == null ? 10 : 8,
        5,
        onRemove == null ? 10 : 6,
        5,
      ),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.11) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: color.withValues(alpha: filled ? 0.22 : 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.1,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.1,
              ),
            ),
          ),
          if (onRemove != null) ...<Widget>[
            const SizedBox(width: 3),
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Icon(Icons.close_rounded, size: 13, color: color),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return body;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: body,
    );
  }
}

/// The stage badge used on lead cards and in the lead sheet.
class StageChip extends StatelessWidget {
  const StageChip(this.stage, {super.key, this.onTap});

  final Stage stage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TagChip(
      stage.label,
      color: stageColor(stage),
      onTap: onTap,
      icon: stage.isClosed
          ? (stage.key == 'lost'
              ? Icons.cancel_rounded
              : Icons.check_circle_rounded)
          : null,
    );
  }
}

/// A lead's risk, shown only when there is something to say.
///
/// Callers gate on `lead.needsAttention` before placing this — see [ChipRow],
/// which cannot tell an empty chip from a real one.
class RiskChip extends StatelessWidget {
  const RiskChip(this.lead, {super.key});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    if (!lead.needsAttention) return const SizedBox.shrink();
    final bool due = lead.followUpDue;
    return TagChip(
      due ? 'Follow-up due' : lead.risk.label,
      color: due ? AppColors.atRisk : riskColor(lead.risk),
      icon: due ? Icons.schedule_rounded : Icons.warning_amber_rounded,
    );
  }
}

/// A horizontally scrolling row of chips that never overflows.
class ChipRow extends StatelessWidget {
  const ChipRow({super.key, required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    // Callers use `if (…)` in the children list to omit a chip entirely, so
    // anything present here is real. Filtering by widget type cannot work: a
    // chip that renders nothing is still its own type, not a SizedBox.
    final List<Widget> visible = children;
    if (visible.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < visible.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 6),
            visible[i],
          ],
        ],
      ),
    );
  }
}
