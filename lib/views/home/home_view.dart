import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/blocs/capture/capture_bloc.dart';
import '../../widgets/section_title.dart';
import '../capture/capture_view.dart';
import '../lookup/lookup_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context, const CaptureView()),
        icon: const Icon(Icons.mic_rounded),
        label: const Text('Talk to Rex'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<CaptureBloc>().add(const CaptureRequested());
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.graphic_eq_rounded, color: colors.onPrimary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Good morning, Savin',
                          style: TextStyle(fontSize: 13, color: Color(0xFF66706D)),
                        ),
                        Text(
                          'Ready to sell smarter?',
                          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      colors.primary,
                      const Color(0xFF2A8D7F),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.auto_awesome_rounded, color: colors.onPrimary),
                    const SizedBox(height: 28),
                    Text(
                      'Ask Rex anything',
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Clients, deals, follow-ups and product knowledge — in seconds.',
                      style: TextStyle(
                        color: colors.onPrimary.withOpacity(0.82),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: colors.primary,
                      ),
                      onPressed: () => _open(context, const LookupView()),
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Start a lookup'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const SectionTitle(title: 'Today'),
              const SizedBox(height: 12),
              const _MeetingCard(),
              const SizedBox(height: 28),
              const SectionTitle(title: 'Pending captures', actionLabel: 'View all'),
              const SizedBox(height: 12),
              BlocBuilder<CaptureBloc, CaptureState>(
                builder: (BuildContext context, CaptureState state) {
                  if (state is CaptureLoaded) {
                    return Column(
                      children: state.captures
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Card(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: colors.secondaryContainer,
                                    child: Icon(
                                      Icons.mic_none_rounded,
                                      color: colors.onSecondaryContainer,
                                    ),
                                  ),
                                  title: Text(
                                    item.clientName,
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(item.summary),
                                  ),
                                  trailing: const Icon(Icons.chevron_right_rounded),
                                  onTap: () => _open(context, const CaptureView()),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  }
                  if (state is CaptureFailure) {
                    return Text(state.message);
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _open(BuildContext context, Widget view) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => view),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  const _MeetingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: <Widget>[
            Container(
              width: 54,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: <Widget>[
                  Text('11:30', style: TextStyle(fontWeight: FontWeight.w800)),
                  Text('AM', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Acme discovery call', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Google Meet · 45 min'),
                ],
              ),
            ),
            const Icon(Icons.videocam_outlined),
          ],
        ),
      ),
    );
  }
}
