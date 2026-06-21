import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/capture.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/state_views.dart';
import '../../capture/view/conversation_view.dart';
import '../../home/view/widgets/capture_tile.dart';
import '../bloc/pending_bloc.dart';

/// The 'Pending capture' queue — ignored prompts land here and are never lost
/// (F3). Tapping one opens the capture flow pre-filled.
class PendingView extends StatelessWidget {
  const PendingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending captures')),
      body: SafeArea(
        top: false,
        child: ContentBounds(
          child: BlocBuilder<PendingBloc, PendingState>(
            builder: (BuildContext context, PendingState state) {
              if (state.status == PendingStatus.loading ||
                  state.status == PendingStatus.initial) {
                return const LoadingView();
              }
              if (state.captures.isEmpty) {
                return const EmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'All caught up',
                  message: 'No captures waiting. New prompts will appear here after meetings.',
                );
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    context.read<PendingBloc>().add(const PendingRequested()),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                  children: state.captures
                      .map((Capture c) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: CaptureTile(
                              capture: c,
                              onTap: () => ConversationView.open(context, source: c)
                                  .then((_) {
                                if (context.mounted) {
                                  context
                                      .read<PendingBloc>()
                                      .add(const PendingRequested());
                                }
                              }),
                            ),
                          ))
                      .toList()
                      .animate(interval: 60.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.08),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
