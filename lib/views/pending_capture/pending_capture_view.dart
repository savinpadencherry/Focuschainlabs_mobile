import 'package:flutter/material.dart';

import '../capture/capture_view.dart';

class PendingCaptureView extends StatelessWidget {
  const PendingCaptureView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending captures')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        children: <Widget>[
          const Text(
            '2 updates waiting for you',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Capture them now so the CRM stays current and follow-ups do not slip.',
            style: TextStyle(color: Color(0xFF68716E), height: 1.45),
          ),
          const SizedBox(height: 24),
          _CaptureCard(
            client: 'Acme',
            title: 'Discovery call',
            time: 'Ended 18 min ago',
            priority: 'Fresh',
            onTap: () => _open(context),
          ),
          const SizedBox(height: 14),
          _CaptureCard(
            client: 'Northstar Industries',
            title: 'Product walkthrough',
            time: 'Yesterday · 4:30 PM',
            priority: 'Overdue',
            onTap: () => _open(context),
          ),
        ],
      ),
    );
  }

  static Future<void> _open(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const CaptureView()),
    );
  }
}

class _CaptureCard extends StatelessWidget {
  const _CaptureCard({
    required this.client,
    required this.title,
    required this.time,
    required this.priority,
    required this.onTap,
  });

  final String client;
  final String title;
  final String time;
  final String priority;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  child: const Icon(Icons.business_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(client, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                      Text(title, style: const TextStyle(color: Color(0xFF68716E))),
                    ],
                  ),
                ),
                Chip(label: Text(priority)),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                const Icon(Icons.schedule_rounded, size: 18),
                const SizedBox(width: 7),
                Expanded(child: Text(time)),
                FilledButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.mic_rounded, size: 18),
                  label: const Text('Capture'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
