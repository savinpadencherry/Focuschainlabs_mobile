import 'package:flutter/material.dart';

import '../capture/capture_view.dart';

class MeetingsView extends StatelessWidget {
  const MeetingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meetings'),
        actions: <Widget>[
          IconButton(onPressed: () {}, icon: const Icon(Icons.tune_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        children: <Widget>[
          _DayHeader(label: 'Today', count: 2),
          const SizedBox(height: 12),
          _MeetingTile(
            time: '11:30 AM',
            title: 'Acme discovery call',
            meta: 'Google Meet · 45 min',
            accent: Theme.of(context).colorScheme.primaryContainer,
            onTap: () => _open(context),
          ),
          const SizedBox(height: 12),
          _MeetingTile(
            time: '3:00 PM',
            title: 'Northstar product walkthrough',
            meta: 'Bengaluru · 60 min',
            accent: Theme.of(context).colorScheme.secondaryContainer,
            onTap: () => _open(context),
          ),
          const SizedBox(height: 28),
          const _DayHeader(label: 'Tomorrow', count: 1),
          const SizedBox(height: 12),
          _MeetingTile(
            time: '10:00 AM',
            title: 'Quarterly pipeline review',
            meta: 'Internal · 30 min',
            accent: Theme.of(context).colorScheme.tertiaryContainer,
            onTap: () {},
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

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        Text('$count meetings', style: const TextStyle(color: Color(0xFF6F7875))),
      ],
    );
  }
}

class _MeetingTile extends StatelessWidget {
  const _MeetingTile({
    required this.time,
    required this.title,
    required this.meta,
    required this.accent,
    required this.onTap,
  });

  final String time;
  final String title;
  final String meta;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.event_available_rounded),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(meta, style: const TextStyle(color: Color(0xFF6F7875))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
