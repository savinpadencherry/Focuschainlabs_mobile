import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The Ona mark: an ink circle with a single "O".
///
/// One widget, sized from the caller, reused from the bubble avatar to the
/// empty state. The web app has the same rule for the same reason — a second
/// copy drifts, and the mark is the one thing that has to look identical
/// everywhere it appears.
class OnaMark extends StatelessWidget {
  const OnaMark({super.key, this.size = 32, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? AppColors.ink,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        'O',
        style: TextStyle(
          color: AppColors.greenBright,
          fontSize: size * 0.58,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The waiting state.
///
/// The mark pulses and the caption cycles, because an Ona turn can take a
/// language-model round trip and a motionless bubble for four seconds reads as
/// a hang. Deliberately vague about *what* it is doing — claiming a specific
/// workflow before the planner has chosen one is a lie the user can catch.
class OnaThinking extends StatefulWidget {
  const OnaThinking({super.key});

  @override
  State<OnaThinking> createState() => _OnaThinkingState();
}

class _OnaThinkingState extends State<OnaThinking>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  static const List<String> _phrases = <String>[
    'thinking…',
    'reading your pipeline…',
    'choosing the workflow…',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        final int index =
            (_controller.lastElapsedDuration?.inMilliseconds ?? 0) ~/ 1800 %
                _phrases.length;
        return Row(
          children: <Widget>[
            Opacity(
              opacity: 0.45 + (_controller.value * 0.55),
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              _phrases[index],
              style: const TextStyle(
                color: AppColors.inkMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        );
      },
    );
  }
}
