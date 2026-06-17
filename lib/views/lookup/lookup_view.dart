import 'dart:async';

import 'package:flutter/material.dart';

class LookupView extends StatefulWidget {
  const LookupView({super.key});

  @override
  State<LookupView> createState() => _LookupViewState();
}

class _LookupViewState extends State<LookupView> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  bool _hasAnswer = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ask([String? question]) async {
    final String value = question ?? _controller.text.trim();
    if (value.isEmpty || _loading) return;
    _controller.text = value;
    setState(() {
      _loading = true;
      _hasAnswer = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _hasAnswer = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ask Mr. Rex')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: <Widget>[
            Text(
              'What do you need to know?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask about clients, open deals, recent activity, follow-ups or product information.',
              style: TextStyle(height: 1.5, color: Color(0xFF68716E)),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _ask(),
              decoration: InputDecoration(
                hintText: 'What is the latest on Acme?',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton.filledTonal(
                  tooltip: 'Ask Rex',
                  onPressed: _ask,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              child: _loading
                  ? const _ThinkingCard(key: ValueKey<String>('loading'))
                  : _hasAnswer
                      ? const _AnswerCard(key: ValueKey<String>('answer'))
                      : _Suggestions(
                          key: const ValueKey<String>('suggestions'),
                          onSelected: _ask,
                        ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.secondaryContainer.withOpacity(0.48),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.verified_outlined, color: colors.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Answers are grounded in your organisation’s connected data and include source references.',
                      style: TextStyle(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.onSelected, super.key});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const List<(IconData, String)> suggestions = <(IconData, String)>[
      (Icons.business_center_outlined, 'Which deals need my attention today?'),
      (Icons.history_rounded, 'Summarise my last interaction with Acme'),
      (Icons.inventory_2_outlined, 'What is our configurator scope and price band?'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Try asking',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        ...suggestions.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(child: Icon(item.$1)),
                title: Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: const Icon(Icons.north_west_rounded, size: 18),
                onTap: () => onSelected(item.$2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ThinkingCard extends StatefulWidget {
  const _ThinkingCard({super.key});

  @override
  State<_ThinkingCard> createState() => _ThinkingCardState();
}

class _ThinkingCardState extends State<_ThinkingCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            RotationTransition(
              turns: _controller,
              child: const Icon(Icons.auto_awesome_rounded),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text('Rex is checking client history, deals and follow-ups…'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  child: Icon(Icons.auto_awesome_rounded, color: colors.primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Acme — concise client 360', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                ),
                const Chip(label: Text('Grounded')),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Acme is currently in a warm stage. They requested a revised quote by Friday, and the next pricing follow-up is planned for Monday. The last interaction was positive, with no active risk signals.',
              style: TextStyle(height: 1.55, fontSize: 15),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const <Widget>[
                Chip(avatar: Icon(Icons.trending_up_rounded, size: 17), label: Text('Warm deal')),
                Chip(avatar: Icon(Icons.task_alt_rounded, size: 17), label: Text('Quote due Friday')),
                Chip(avatar: Icon(Icons.event_rounded, size: 17), label: Text('Follow-up Monday')),
              ],
            ),
            const Divider(height: 30),
            const Text('Sources', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.notes_rounded),
              title: Text('CRM interaction · Today, 11:58 AM'),
            ),
            const ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.email_outlined),
              title: Text('Recent email subject · Revised proposal'),
            ),
          ],
        ),
      ),
    );
  }
}
