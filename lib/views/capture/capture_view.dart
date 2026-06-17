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
    return Scaffold(
      appBar: AppBar(title: const Text('Capture update')),
      body: Center(
        child: FilledButton.icon(
          onPressed: () => setState(() => _recording = !_recording),
          icon: Icon(_recording ? Icons.stop : Icons.mic),
          label: Text(_recording ? 'Stop' : 'Start speaking'),
        ),
      ),
    );
  }
}
