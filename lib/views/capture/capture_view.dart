import 'package:flutter/material.dart';

class CaptureView extends StatefulWidget {
  const CaptureView({super.key});

  @override
  State<CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<CaptureView> {
  bool _recording = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture update'),
        actions: <Widget>[
          TextButton(onPressed: () {}, child: const Text('Type instead')),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
          child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  children: <Widget>[
                    CircleAvatar(child: Icon(Icons.business_outlined)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Acme discovery call', style: TextStyle(fontWeight: FontWeight.w800)),
                          SizedBox(height: 3),
                          Text('Today · 11:30 AM · 45 minutes'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: _recording ? 148 : 128,
                height: _recording ? 148 : 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _recording ? colors.errorContainer : colors.primaryContainer,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: (_recording ? colors.error : colors.primary).withOpacity(0.18),
                      blurRadius: 34,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  _recording ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                  size: 58,
                  color: _recording ? colors.error : colors.primary,
                ),
              ),
              const SizedBox(height: 34),
              Text(
                _recording ? 'Listening…' : 'Tell Rex what happened',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                _recording
                    ? 'Speak naturally. You can pause whenever you need.'
                    : 'Rex will turn your recap into a CRM update, action items and follow-ups.',
                style: const TextStyle(height: 1.5, color: Color(0xFF68716E)),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => setState(() => _recording = !_recording),
                  icon: Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded),
                  label: Text(_recording ? 'Stop recording' : 'Start speaking'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your transcript will be shown for review before anything is saved.',
                style: TextStyle(fontSize: 12, color: Color(0xFF7A8380)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
