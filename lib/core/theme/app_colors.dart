import 'package:flutter/material.dart';

/// The Secona palette, from the brand guidelines.
///
/// Ink is a deep violet-black rather than a neutral one, and the surfaces are
/// tinted the same way — that is what makes the iris read as the brand colour
/// instead of as a highlight sitting on a grey app. Green is the accent, not
/// the primary: it marks the live, the confirmed and the affirmative, which is
/// why it is what a Save button and a "Won" badge are made of.
///
/// The token names are unchanged from the previous theme on purpose. They are
/// used in about forty files, and renaming them would have made this a diff
/// nobody could review for the thing that actually changed — the colours.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  /// Iris. The primary.
  static const Color iris = Color(0xFF7350D0);
  static const Color irisDeep = Color(0xFF5B3EA8);

  /// Ona green. The accent.
  static const Color onaGreen = Color(0xFF5FB800);
  static const Color onaGreenDeep = Color(0xFF4C9400);

  // ── Surfaces ───────────────────────────────────────────────────────────────
  static const Color paper = Color(0xFFF6F4FB);
  static const Color paper2 = Color(0xFFEEEBF7);
  static const Color paper3 = Color(0xFFE7E3F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEEEBF7);

  // ── Ink ────────────────────────────────────────────────────────────────────
  static const Color ink = Color(0xFF161026);
  static const Color inkSoft = Color(0xFF4A4160);
  static const Color inkMuted = Color(0xFF7C7392);

  // ── Structural ─────────────────────────────────────────────────────────────
  /// `navy` in the old palette. Kept as a name because it is the structural
  /// non-accent colour across the app; it is iris now.
  static const Color navy = iris;
  static const Color navyDeep = irisDeep;
  static const Color hero1 = Color(0xFF161026);
  static const Color hero2 = Color(0xFF1E1733);
  static const Color hero3 = Color(0xFF2A2440);
  static const Color hero4 = Color(0xFF221A3D);

  // ── Accent ─────────────────────────────────────────────────────────────────
  static const Color green = onaGreen;
  static const Color greenDeep = onaGreenDeep;
  static const Color greenBright = Color(0xFF74D400);
  static const Color greenSoft = Color(0xFFDCF0C4);

  // ── Aliases used across the app ────────────────────────────────────────────
  static const Color primary = iris;
  static const Color primaryDark = irisDeep;
  static const Color accent = onaGreen;
  static const Color background = paper;
  static const Color textPrimary = ink;
  static const Color textSecondary = inkSoft;
  static const Color textMuted = inkMuted;
  static const Color cardBorder = Color(0xFFE7E3F2);
  static const Color cardBorderStrong = Color(0xFFD8D2ED);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color positive = onaGreen;
  static const Color neutral = Color(0xFF7C7392);
  static const Color negative = Color(0xFFD64545);
  static const Color atRisk = Color(0xFFE07B39);

  // ── Gradients ──────────────────────────────────────────────────────────────
  /// The mark's own two bars, in the mark's own order.
  static const List<Color> brandGradient = <Color>[iris, onaGreen];
  static const List<Color> logoGradient = <Color>[Color(0xFF8A6BE0), irisDeep];
  static const List<Color> heroGradient = <Color>[hero1, hero2, hero3, hero4];
  static const List<Color> splashGradient = <Color>[hero1, hero2, hero3];

  // ── Glows / shadows ────────────────────────────────────────────────────────
  static const Color greenGlow = Color(0x735FB800);
  static const Color greenHalo = Color(0x2E5FB800);
  static const Color navyShadow = Color(0x8C7350D0);

  /// Sentiment value (extraction schema) → colour.
  static Color sentiment(String value) {
    switch (value) {
      case 'positive':
        return positive;
      case 'negative':
        return negative;
      case 'at_risk':
        return atRisk;
      default:
        return neutral;
    }
  }
}
