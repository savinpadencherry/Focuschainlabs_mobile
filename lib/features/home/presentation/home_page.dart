import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mr. Rex')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const CapturePage()),
        ),
        icon: const Icon(Icons.mic),
        label: const Text('Talk to Rex'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: <Widget>[
          Card(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Ask about a client or offering'),
              subtitle: const Text('What is the latest on Acme?'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const LookupPage()),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Today', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Text('11:30'),
              title: Text('Acme discovery call'),
              subtitle: Text('Client meeting'),
            ),
          ),
          const SizedBox(height: 24),
          Text('Pending captures', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.mic_none),
              title: const Text('How did the Acme meeting go?'),
              subtitle: const Text('Ended 18 minutes ago'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const CapturePage()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LookupPage extends StatelessWidget {
  const LookupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask Mr. Rex')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Ask about a client, deal, or product',
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),
    );
  }
}

class CapturePage extends StatefulWidget {
  const CapturePage({super.key});

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  bool recording = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture update')),
      body: Center(
        child: FilledButton.icon(
          onPressed: () => setState(() => recording = !recording),
          icon: Icon(recording ? Icons.stop : Icons.mic),
          label: Text(recording ? 'Stop' : 'Start speaking'),
        ),
      ),
    );
  }
}
