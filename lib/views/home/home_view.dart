import 'package:flutter/material.dart';

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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF0F766E), Color(0xFF14B8A6)],
                    ),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(Icons.graphic_eq_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Good morning, Savin', style: TextStyle(fontSize: 13, color: Color(0xFF66706D))),
                      Text('Ready to sell smarter?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF0F766E), Color(0xFF115E59)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                  ),
                  const SizedBox(height: 28),
                  const Text('Ask Rex anything', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text(
                    'Clients, deals, follow-ups and product knowledge — in seconds.',
                    style: TextStyle(color: Colors.white70, height: 1.45, fontSize: 15),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: colors.primary),
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
            _CaptureCard(
              client: 'Acme',
              subtitle: 'Discovery call ended 18 minutes ago',
              onTap: () => _open(context, const CaptureView()),
            ),
            const SizedBox(height: 12),
            _CaptureCard(
              client: 'Northstar Industries',
              subtitle: 'Product walkthrough · Yesterday',
              onTap: () => _open(context, const CaptureView()),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _open(BuildContext context, Widget view) {
    return Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => view));
  }
}

class _CaptureCard extends StatelessWidget {
  const _CaptureCard({required this.client, required this.subtitle, required this.onTap});

  final String client;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: const Icon(Icons.mic_none_rounded),
        ),
        title: Text(client, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
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
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: <Widget>[
                  Text('11:30', style: TextStyle(fontWeight: FontWeight.w900)),
                  Text('AM', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Acme discovery call', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Google Meet · 45 min', style: TextStyle(color: Color(0xFF68716E))),
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
