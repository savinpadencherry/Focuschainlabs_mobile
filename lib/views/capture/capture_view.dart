import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../capture_review/capture_review_view.dart';

class CaptureView extends StatefulWidget {
  const CaptureView({super.key});

  @override
  State<CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<CaptureView> with SingleTickerProviderStateMixin {
  bool _recording = false;
  int _seconds = 0;
  Timer? _timer;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _recording = true;
      _seconds = 0;
    });
    _pulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  void _stopAndReview() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() => _recording = false);
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const CaptureReviewView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String elapsed = '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture update'),
        actions: <Widget>[
          TextButton(
            onPressed: _showTypeInstead,
            child: const Text('Type instead'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: const <Widget>[
                      CircleAvatar(child: Icon(Icons.business_outlined)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Acme discovery call', style: TextStyle(fontWeight: FontWeight.w900)),
                            SizedBox(height: 3),
                            Text('Today · 11:30 AM · 45 minutes'),
                          ],
                        ),
                      ),
                      Chip(label: Text('Matched')),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (BuildContext context, Widget? child) {
                  final double pulse = _recording ? 1 + (_pulseController.value * 0.08) : 1;
                  return Transform.scale(
                    scale: pulse,
                    child: Container(
                      width: 152,
                      height: 152,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _recording
                              ? <Color>[colors.errorContainer, colors.error.withOpacity(0.28)]
                              : <Color>[colors.primaryContainer, colors.secondaryContainer],
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: (_recording ? colors.error : colors.primary).withOpacity(0.18),
                            blurRadius: 34,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        _recording ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                        size: 62,
                        color: _recording ? colors.error : colors.primary,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 26),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: Text(
                  _recording ? 'Listening…' : 'Tell Rex what happened',
                  key: ValueKey<bool>(_recording),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _recording
                    ? 'Speak naturally. Rex will structure the recap for review.'
                    : 'Your recap becomes a CRM update, tasks and follow-ups.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF68716E), height: 1.5),
              ),
              const SizedBox(height: 18),
              AnimatedOpacity(
                opacity: _recording ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: Column(
                  children: <Widget>[
                    Text(elapsed, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 34,
                      child: CustomPaint(
                        painter: _WavePainter(progress: _pulseController.value, color: colors.primary),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _recording ? _stopAndReview : _startRecording,
                  icon: Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded),
                  label: Text(_recording ? 'Stop and review' : 'Start speaking'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Nothing is saved until you confirm the extracted update.',
                style: TextStyle(fontSize: 12, color: Color(0xFF7A8380)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTypeInstead() async {
    final TextEditingController controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Type your update', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  hintText: 'Called Acme. They want a revised quote by Friday…',
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(this.context).push<void>(
                      MaterialPageRoute<void>(builder: (_) => const CaptureReviewView()),
                    );
                  },
                  child: const Text('Continue to review'),
                ),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const int bars = 24;
    final double gap = size.width / bars;
    for (int i = 0; i < bars; i++) {
      final double normalized = (math.sin((i * 0.8) + (progress * math.pi * 2)) + 1) / 2;
      final double height = 8 + normalized * (size.height - 8);
      final double x = (i * gap) + gap / 2;
      canvas.drawLine(Offset(x, (size.height - height) / 2), Offset(x, (size.height + height) / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color;
}
