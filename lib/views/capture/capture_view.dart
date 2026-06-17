import 'package:flutter/material.dart';
import '../capture_review/capture_review_view.dart';

class CaptureView extends StatefulWidget {
  const CaptureView({super.key});

  @override
  State<CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<CaptureView> {
  bool recording = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Capture update')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: const [
                      CircleAvatar(child: Icon(Icons.business_outlined)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Acme discovery call', style: TextStyle(fontWeight: FontWeight.w800)),
                            Text('Today · 11:30 AM · 45 minutes'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              CircleAvatar(
                radius: recording ? 72 : 62,
                backgroundColor: recording ? colors.errorContainer : colors.primaryContainer,
                child: Icon(
                  recording ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                  size: 58,
                  color: recording ? colors.error : colors.primary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                recording ? 'Listening…' : 'Tell Rex what happened',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                recording
                    ? 'Speak naturally. Rex is listening.'
                    : 'Your recap becomes a CRM update, tasks and follow-ups.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF68716E), height: 1.5),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    if (recording) {
                      setState(() => recording = false);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const CaptureReviewView()),
                      );
                    } else {
                      setState(() => recording = true);
                    }
                  },
                  icon: Icon(recording ? Icons.stop_rounded : Icons.mic_rounded),
                  label: Text(recording ? 'Stop and review' : 'Start speaking'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
