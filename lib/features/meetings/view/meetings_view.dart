import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/capture.dart';
import '../../../core/models/meeting.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/state_views.dart';
import '../../capture/view/conversation_view.dart';
import '../../home/view/widgets/meeting_tile.dart';
import '../bloc/meetings_bloc.dart';

/// Day view of meetings split into upcoming and ended (with capture prompts).
class MeetingsView extends StatelessWidget {
  const MeetingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meetings')),
      body: SafeArea(
        top: false,
        child: ContentBounds(
          child: BlocBuilder<MeetingsBloc, MeetingsState>(
            builder: (BuildContext context, MeetingsState state) {
              if (state.status == MeetingsStatus.loading ||
                  state.status == MeetingsStatus.initial) {
                return const LoadingView(label: 'Loading your calendar…');
              }
              if (state.meetings.isEmpty) {
                return const EmptyState(
                  icon: Icons.event_busy_rounded,
                  title: 'No meetings today',
                  message: 'When a meeting ends, Rex will prompt you to capture it.',
                );
              }
              return _MeetingsList(meetings: state.meetings);
            },
          ),
        ),
      ),
    );
  }
}

class _MeetingsList extends StatelessWidget {
  const _MeetingsList({required this.meetings});

  final List<Meeting> meetings;

  @override
  Widget build(BuildContext context) {
    final List<Meeting> upcoming =
        meetings.where((Meeting m) => !m.hasEnded).toList();
    final List<Meeting> ended =
        meetings.where((Meeting m) => m.hasEnded).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: <Widget>[
        if (upcoming.isNotEmpty) ...<Widget>[
          const SectionHeader(title: 'Upcoming'),
          AppSpacing.vGapMd,
          ...upcoming.map((Meeting m) => _tile(context, m)),
          AppSpacing.vGapXl,
        ],
        if (ended.isNotEmpty) ...<Widget>[
          const SectionHeader(title: 'Ended'),
          AppSpacing.vGapMd,
          ...ended.map((Meeting m) => _tile(context, m)),
        ],
      ].animate(interval: 50.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06),
    );
  }

  Widget _tile(BuildContext context, Meeting m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: MeetingTile(
        meeting: m,
        onTap: m.awaitingCapture
            ? () => ConversationView.open(
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
    );
  }
}
