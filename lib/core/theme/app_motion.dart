import 'package:flutter/animation.dart';

/// Shared motion language, matching the website's choreography: a single
/// signature easing curve and a small set of durations used for entrances,
/// floats and pulses.
abstract final class AppMotion {
  /// The site's primary easing — `cubic-bezier(.22, 1, .36, 1)`.
  static const Cubic ease = Cubic(0.22, 1, 0.36, 1);

  static const Duration fast = Duration(milliseconds: 220);
  static const Duration base = Duration(milliseconds: 360);
  static const Duration slow = Duration(milliseconds: 560);
  static const Duration reveal = Duration(milliseconds: 720);

  /// Continuous loops (float / glow pulse).
  static const Duration float = Duration(milliseconds: 3600);
  static const Duration pulse = Duration(milliseconds: 2000);
}
