import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';

/// Three bouncing dots shown while Rex composes a grounded answer.
class TypingDots extends StatelessWidget {
  const TypingDots({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(3, (int i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 4),
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (AnimationController c) => c.repeat())
              .fadeIn(duration: 300.ms, delay: (i * 150).ms)
              .then()
              .fadeOut(duration: 300.ms),
        );
      }),
    );
  }
}
