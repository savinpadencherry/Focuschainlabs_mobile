import 'package:flutter/material.dart';

class LookupView extends StatefulWidget {
  const LookupView({super.key});

  @override
  State<LookupView> createState() => _LookupViewState();
}

class _LookupViewState extends State<LookupView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
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
              decoration: InputDecoration(
                hintText: 'What is the latest on Acme?',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton.filledTonal(
                  tooltip: 'Speak your question',
                  onPressed: () {},
                  icon: const Icon(Icons.mic_rounded),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Try asking',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            _SuggestionCard(
              icon: Icons.business_center_outlined,
              text: 'Which deals need my attention today?',
              onTap: () => _setQuestion('Which deals need my attention today?'),
            ),
            const SizedBox(height: 10),
            _SuggestionCard(
              icon: Icons.history_rounded,
              text: 'Summarise my last interaction with Acme',
              onTap: () => _setQuestion('Summarise my last interaction with Acme'),
            ),
            const SizedBox(height: 10),
            _SuggestionCard(
              icon: Icons.inventory_2_outlined,
              text: 'What is our configurator scope and price band?',
              onTap: () => _setQuestion(
                'What is our configurator scope and price band?',
              ),
            ),
            const SizedBox(height: 28),
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
                      'Rex will answer only from your organisation’s connected data and show the source behind every answer.',
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

  void _setQuestion(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.north_west_rounded, size: 18),
        onTap: onTap,
      ),
    );
  }
}
