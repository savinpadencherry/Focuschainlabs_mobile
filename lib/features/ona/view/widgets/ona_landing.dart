import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/get.dart';
import '../../../../core/models/ona.dart';
import '../../../../core/models/pipeline.dart';
import '../../../../core/repository/crm_repository.dart';
import '../../../../core/services/api/identity_cache.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/crm_chips.dart';
import '../../bloc/ona_bloc.dart';
import 'ona_lead_tile.dart';
import 'ona_mark.dart';

/// The opening screen: a greeting, the ask box, and the day underneath it.
///
/// The first version put the brief in a chat bubble at the top and left the
/// rest of a tall phone empty, with the box pinned to the bottom edge. That
/// reads as a chat someone has already abandoned. Here the box is the centre
/// of the screen because asking is the point of the surface, and what is
/// waiting sits directly beneath it as things you can open — not counters you
/// can only read.
///
/// It is replaced by the thread the moment a question is asked; see
/// [OnaView] for the switch.
class OnaLanding extends StatelessWidget {
  const OnaLanding({
    super.key,
    required this.brief,
    required this.composer,
    required this.onChip,
  });

  /// The briefing answer, when it has arrived.
  final OnaAnswer? brief;

  /// The ask box, built by the parent so it owns the controller.
  final Widget composer;
  final ValueChanged<String> onChip;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: <Widget>[
        const SizedBox(height: 18),
        const _Greeting(),
        const SizedBox(height: 22),
        composer
            .animate()
            .fadeIn(delay: 120.ms, duration: 340.ms)
            .slideY(begin: 0.18, curve: Curves.easeOutCubic),
        const SizedBox(height: 14),
        _Chips(onChip: onChip)
            .animate()
            .fadeIn(delay: 220.ms, duration: 300.ms),
        const SizedBox(height: 26),
        _Day(brief: brief, onChip: onChip),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  static String _partOfDay() {
    final int h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final String first =
        (IdentityCache.current?.name ?? '').trim().split(' ').first;

    return Column(
      children: <Widget>[
        const OnaMark(size: 56)
            .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.05, 1.05),
              duration: 2400.ms,
              curve: Curves.easeInOut,
            ),
        const SizedBox(height: 16),
        Text(
          first.isEmpty ? _partOfDay() : '${_partOfDay()}, $first',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
        ).animate().fadeIn(duration: 380.ms).slideY(begin: 0.2),
        const SizedBox(height: 6),
        Text(
          'What would you like to do?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.inkMuted,
              ),
        ).animate().fadeIn(delay: 80.ms, duration: 380.ms),
      ],
    );
  }
}

/// The 1-tap chips, named after this tenant's own area and leads.
///
/// The fixed list this replaces suggested one agency's client and locality to
/// everybody, so a second agency tapping "Lead Srikant Patra" searched their
/// CRM for a person who had never been in it.
class _Chips extends StatefulWidget {
  const _Chips({required this.onChip});

  final ValueChanged<String> onChip;

  @override
  State<_Chips> createState() => _ChipsState();
}

class _ChipsState extends State<_Chips> {
  List<OnaOffer> _chips = const <OnaOffer>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<OnaOffer> chips = await app<CrmRepository>().suggestions();
    if (mounted) setState(() => _chips = chips);
  }

  @override
  Widget build(BuildContext context) {
    if (_chips.isEmpty) return const SizedBox(height: 32);
    final bool busy = context.select((OnaBloc b) => b.state.busy);
    return Column(
      children: <Widget>[
        Text(
          'Try 1-tap search',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          alignment: WrapAlignment.center,
          children: <Widget>[
            for (final OnaOffer c in _chips)
              TagChip(
                c.label,
                color: AppColors.iris,
                filled: false,
                onTap: busy ? null : () => widget.onChip(c.prompt),
              ),
          ],
        ),
      ],
    );
  }
}

/// What is waiting today, as things you can open.
///
/// The counters in the first version told a rep there were two follow-ups due
/// and then made them go and find out which two. These are the actual leads.
class _Day extends StatelessWidget {
  const _Day({required this.brief, required this.onChip});

  final OnaAnswer? brief;
  final ValueChanged<String> onChip;

  @override
  Widget build(BuildContext context) {
    if (brief == null) return const _DaySkeleton();

    final List<Map<String, dynamic>> due =
        asMaps(brief!.tasks['due_now']).take(3).toList();
    final List<Map<String, dynamic>> risky =
        asMaps(brief!.risk['deals']).take(3).toList();

    if (due.isEmpty && risky.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.check_circle_rounded,
                color: AppColors.green, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Nothing overdue and nothing waiting. Good time to work the '
                'pipeline.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 300.ms, duration: 340.ms);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (due.isNotEmpty)
          _Section(
            label: 'Due now',
            accent: AppColors.atRisk,
            icon: Icons.schedule_rounded,
            rows: due,
            more: due.length < asMaps(brief!.tasks['due_now']).length
                ? 'What follow-ups are due?'
                : null,
            onMore: onChip,
            delayMs: 300,
          ),
        if (due.isNotEmpty && risky.isNotEmpty) const SizedBox(height: 18),
        if (risky.isNotEmpty)
          _Section(
            label: 'Going quiet',
            accent: AppColors.negative,
            icon: Icons.trending_down_rounded,
            rows: risky,
            more: risky.length < asMaps(brief!.risk['deals']).length
                ? 'Which deals are at risk?'
                : null,
            onMore: onChip,
            delayMs: 380,
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.accent,
    required this.icon,
    required this.rows,
    required this.onMore,
    required this.delayMs,
    this.more,
  });

  final String label;
  final Color accent;
  final IconData icon;
  final List<Map<String, dynamic>> rows;
  final String? more;
  final ValueChanged<String> onMore;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: 7),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: accent,
              ),
            ),
            const Spacer(),
            Text(
              '${rows.length}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        for (final Map<String, dynamic> row in rows) OnaLeadTile(row: row),
        if (more != null) ...<Widget>[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => onMore(more!),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: const Text('See all'),
            ),
          ),
        ],
      ],
    )
        .animate(delay: delayMs.ms)
        .fadeIn(duration: 340.ms)
        .slideY(begin: 0.12, curve: Curves.easeOutCubic);
  }
}

class _DaySkeleton extends StatelessWidget {
  const _DaySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < 2; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
      ],
    ).animate(onPlay: (AnimationController c) => c.repeat(reverse: true)).fadeIn(
          duration: 900.ms,
          begin: 0.45,
        );
  }
}
