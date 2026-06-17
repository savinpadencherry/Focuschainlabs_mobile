import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/capture.dart';
import '../../../core/models/meeting.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../capture/view/capture_view.dart';
import '../../pending/view/pending_page.dart';
import '../bloc/home_bloc.dart';
import 'widgets/activity_tile.dart';
import 'widgets/ask_rex_card.dart';
import 'widgets/capture_tile.dart';
import 'widgets/home_header.dart';
import 'widgets/meeting_tile.dart';

/// The lightweight home surface (F10): greeting, lookup entry, today's
/// meetings, pending captures and recent updates. Adapts from a single column
/// on phones to two columns on tablet/web.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  Future<void> _refresh(BuildContext context) async {
    context.read<HomeBloc>().add(const HomeLoaded());
    await context.read<HomeBloc>().stream.firstWhere(
          (HomeState s) => s.status != HomeStatus.loading,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (BuildContext context, HomeState state) {
              return ContentBounds(
                child: ResponsiveLayout(
                  mobile: (_) => _SingleColumn(state: state),
                  tablet: (_) => _TwoColumn(state: state),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Opens the capture flow for a pending capture or meeting.
void _openCapture(BuildContext context, {Capture? source}) {
  CaptureView.open(context, source: source).then((_) {
    if (context.mounted) context.read<HomeBloc>().add(const HomeLoaded());
  });
}

class _SingleColumn extends StatelessWidget {
  const _SingleColumn({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: _staggered(<Widget>[
        HomeHeader(user: context.select((AuthBloc b) => b.state.user)),
        AppSpacing.vGapXl,
        const AskRexCard(),
        AppSpacing.vGapXxl,
        ..._meetingsSection(context, state),
        AppSpacing.vGapXxl,
        ..._pendingSection(context, state),
        if (state.activity.isNotEmpty) ...<Widget>[
          AppSpacing.vGapXxl,
          ..._activitySection(context, state),
        ],
      ]),
    );
  }
}

class _TwoColumn extends StatelessWidget {
  const _TwoColumn({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 120),
      children: _staggered(<Widget>[
        HomeHeader(user: context.select((AuthBloc b) => b.state.user)),
        AppSpacing.vGapXl,
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 5,
                child: Column(
                  children: <Widget>[
                    const AskRexCard(),
                    AppSpacing.vGapXxl,
                    ..._meetingsSection(context, state),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 4,
                child: Column(
                  children: <Widget>[
                    ..._pendingSection(context, state),
                    if (state.activity.isNotEmpty) ...<Widget>[
                      AppSpacing.vGapXxl,
                      ..._activitySection(context, state),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

List<Widget> _meetingsSection(BuildContext context, HomeState state) {
  if (state.status == HomeStatus.loading && state.meetings.isEmpty) {
    return <Widget>[const SectionHeader(title: 'Today'), AppSpacing.vGapMd, const SkeletonBox()];
  }
  final List<Meeting> meetings = state.meetings;
  return <Widget>[
    const SectionHeader(title: 'Today'),
    AppSpacing.vGapMd,
    if (meetings.isEmpty)
      const _MiniEmpty(text: 'No meetings today.')
    else
      ...meetings.take(3).map((Meeting m) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: MeetingTile(
              meeting: m,
              onTap: m.awaitingCapture
                  ? () => _openCapture(
                        context,
                        source: Capture(
                          id: 'cap-${m.id}',
                          clientName: m.clientName,
                          summary: 'Capture the outcome of ${m.title}.',
                          createdAt: DateTime.now(),
                          source: CaptureSource.postMeeting,
                          meetingId: m.id,
                        ),
                      )
                  : null,
            ),
          )),
  ];
}

List<Widget> _pendingSection(BuildContext context, HomeState state) {
  final List<Capture> pending = state.pending;
  return <Widget>[
    SectionHeader(
      title: 'Pending captures',
      actionLabel: pending.isEmpty ? null : 'View all',
      onAction: () => PendingPage.open(context),
    ),
    AppSpacing.vGapMd,
    if (pending.isEmpty)
      const _MiniEmpty(text: 'All caught up — nothing to capture.')
    else
      ...pending.take(3).map((Capture c) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: CaptureTile(
              capture: c,
              onTap: () => _openCapture(context, source: c),
            ),
          )),
  ];
}

List<Widget> _activitySection(BuildContext context, HomeState state) {
  return <Widget>[
    const SectionHeader(title: 'Recent updates'),
    AppSpacing.vGapMd,
    ...state.activity.take(4).map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ActivityTile(entry: entry),
        )),
  ];
}

/// Applies a gentle staggered entrance to the top-level children.
List<Widget> _staggered(List<Widget> children) {
  return <Widget>[
    for (int i = 0; i < children.length; i++)
      children[i]
          .animate()
          .fadeIn(delay: (40 * i).ms, duration: 360.ms)
          .slideY(begin: 0.08, curve: Curves.easeOut),
  ];
}

class _MiniEmpty extends StatelessWidget {
  const _MiniEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: const Color(0xFFE5ECE9)),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
