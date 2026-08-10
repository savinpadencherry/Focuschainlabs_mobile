import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/models/pipeline.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/crm_chips.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/shimmer.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/surface_header.dart';
import '../bloc/pipeline_bloc.dart';
import 'widgets/lead_card.dart';
import 'widgets/lead_sheet.dart';

/// The pipeline board.
///
/// A phone cannot show six kanban columns side by side and stay readable, so
/// the stages become a filter strip over one scrolling list. What matters —
/// which stage, how many, in priority order — survives; only the horizontal
/// dragging is gone, and dragging was never the point.
class PipelineView extends StatelessWidget {
  const PipelineView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<PipelineBloc, PipelineState>(
          builder: (BuildContext context, PipelineState state) {
            return Column(
              children: <Widget>[
                SurfaceHeader(
                  title: AppStrings.pipelineTitle,
                  subtitle: _subtitle(state),
                  trailing: _ValueBadge(stats: state.board.stats),
                ),
                _Controls(state: state),
                RefreshBar(visible: state.isRefreshing),
                Expanded(child: _Body(state: state)),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _subtitle(PipelineState state) {
    if (state.isLoading) return 'Loading…';
    final PipelineStats s = state.board.stats;
    return '${s.active} active · ${s.won} won · ${s.lost} lost';
  }
}

/// Total open pipeline value, counted up rather than snapped in.
///
/// The number is the headline of the surface; letting it tick up draws the eye
/// to it once, on arrival, without needing a colour or a box to shout with.
class _ValueBadge extends StatelessWidget {
  const _ValueBadge({required this.stats});

  final PipelineStats stats;

  @override
  Widget build(BuildContext context) {
    if (stats.total == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            stats.valueFmt,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              height: 1,
              color: AppColors.greenDeep,
            ),
          ),
          const SizedBox(height: 1),
          const Text(
            'in play',
            style: TextStyle(fontSize: 10, color: AppColors.inkMuted),
          ),
        ],
      ),
    )
        .animate(key: ValueKey<String>(stats.valueFmt))
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }
}

class _Controls extends StatefulWidget {
  const _Controls({required this.state});

  final PipelineState state;

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.state.search);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
      child: ContentBounds(
        child: Column(
          children: <Widget>[
            RoundedSearchField(
              controller: _controller,
              hint: AppStrings.pipelineSearchHint,
              onSubmitted: (String q) =>
                  context.read<PipelineBloc>().add(PipelineSearched(q.trim())),
              onClear: widget.state.search.isEmpty
                  ? null
                  : () {
                      _controller.clear();
                      context
                          .read<PipelineBloc>()
                          .add(const PipelineSearched(''));
                    },
            ),
            AppSpacing.vGapMd,
            _StageFilter(state: widget.state),
          ],
        ),
      ),
    );
  }
}

class _StageFilter extends StatelessWidget {
  const _StageFilter({required this.state});

  final PipelineState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          _FilterPill(
            label: 'All',
            count: state.board.leads.length,
            selected: state.stage == null,
            color: AppColors.navy,
            onTap: () =>
                context.read<PipelineBloc>().add(const PipelineStageFiltered(null)),
          ),
          for (final Stage s in Stage.values) ...<Widget>[
            const SizedBox(width: 6),
            _FilterPill(
              label: s.label,
              count: state.board.countIn(s),
              selected: state.stage == s,
              color: stageColor(s),
              onTap: () =>
                  context.read<PipelineBloc>().add(PipelineStageFiltered(s)),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: selected ? color : AppColors.cardBorder),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: color.withValues(alpha: 0.32),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.inkSoft,
              ),
              child: Text(label),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.24)
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final PipelineState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const SkeletonList();

    if (state.status == PipelineStatus.failed && state.board.leads.isEmpty) {
      return ErrorView(
        message: state.error,
        onRetry: () => context.read<PipelineBloc>().add(const PipelineLoaded()),
      );
    }

    final List<Lead> leads = state.visible;
    if (leads.isEmpty) return _Empty(state: state);

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: () async =>
          context.read<PipelineBloc>().add(const PipelineLoaded()),
      child: ContentBounds(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          itemCount: leads.length,
          separatorBuilder: (_, __) => AppSpacing.vGapMd,
          itemBuilder: (BuildContext context, int i) {
            return LeadCard(
              lead: leads[i],
              onTap: () => LeadSheet.open(context, leads[i].id),
            )
                // Staggered, and capped: past the eighth card the delay would
                // outlast the scroll and cards would fade in under the thumb.
                .animate(delay: (i.clamp(0, 8) * 45).ms)
                .fadeIn(duration: 280.ms)
                .slideY(begin: 0.12, curve: Curves.easeOutCubic);
          },
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.state});

  final PipelineState state;

  @override
  Widget build(BuildContext context) {
    final bool filtered = state.search.isNotEmpty || state.stage != null;
    return EmptyState(
      icon: filtered ? Icons.filter_alt_off_rounded : Icons.view_kanban_outlined,
      title: state.search.isNotEmpty
          ? 'No leads match “${state.search}”'
          : (state.stage != null
              ? 'Nothing in ${state.stage!.label}'
              : AppStrings.pipelineEmpty),
      message: filtered
          ? 'Clear the filter to see the rest of your pipeline.'
          : 'Leads added on the web app show up here straight away.',
      action: filtered
          ? FilledButton.tonal(
              onPressed: () {
                final PipelineBloc bloc = context.read<PipelineBloc>();
                bloc.add(const PipelineStageFiltered(null));
                if (state.search.isNotEmpty) {
                  bloc.add(const PipelineSearched(''));
                }
              },
              child: const Text('Show everything'),
            )
          : null,
    ).animate().fadeIn(duration: 340.ms).scale(begin: const Offset(0.96, 0.96));
  }
}
