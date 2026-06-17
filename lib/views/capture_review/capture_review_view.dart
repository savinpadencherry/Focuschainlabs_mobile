import 'package:flutter/material.dart';

class CaptureReviewView extends StatelessWidget {
  const CaptureReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Review update')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      children: <Widget>[
                        Icon(Icons.auto_awesome_rounded),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Rex extracted this update from your voice note. Review it before saving.',
                            style: TextStyle(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _ReviewSection(
                    title: 'Client',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Icon(Icons.business_outlined)),
                      title: Text('Acme', style: TextStyle(fontWeight: FontWeight.w900)),
                      subtitle: Text('Matched with high confidence'),
                      trailing: Icon(Icons.edit_outlined),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _ReviewSection(
                    title: 'CRM update',
                    child: Text(
                      'Acme requested a revised quote by Friday. The opportunity is warm and moving forward.',
                      style: TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _ReviewSection(
                    title: 'Deal stage',
                    child: Row(
                      children: <Widget>[
                        Chip(label: Text('Qualified')),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.arrow_forward_rounded),
                        ),
                        Chip(label: Text('Warm')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _ReviewSection(
                    title: 'Action items',
                    child: Column(
                      children: <Widget>[
                        CheckboxListTile(
                          value: true,
                          onChanged: null,
                          contentPadding: EdgeInsets.zero,
                          title: Text('Send revised quote'),
                          subtitle: Text('Due Friday · Assigned to Savin'),
                        ),
                        Divider(height: 1),
                        CheckboxListTile(
                          value: true,
                          onChanged: null,
                          contentPadding: EdgeInsets.zero,
                          title: Text('Schedule pricing follow-up'),
                          subtitle: Text('Next Monday'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _ReviewSection(
                    title: 'Transcript',
                    child: Text(
                      'Called Acme. They want a revised quote by Friday and the deal is looking warm. Follow up with pricing next Monday.',
                      style: TextStyle(color: Color(0xFF68716E), height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Update saved successfully')),
                    );
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Confirm and save'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
