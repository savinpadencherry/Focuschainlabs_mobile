import 'package:flutter/material.dart';

/// Mr. Rex palette — aligned to the FocusChain Labs website: warm "paper"
/// surfaces, deep navy ink, and an emerald-green spark, with a dark navy hero.
/// Reference every colour decision here so re-theming stays a one-file job.
abstract final class AppColors {
  // Paper / surfaces (warm cream)
  static const Color paper = Color(0xFFF7F3EC);
  static const Color paper2 = Color(0xFFEFEAE0);
  static const Color paper3 = Color(0xFFE7E1D5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1EDE4);

  // Ink / navy text
  static const Color ink = Color(0xFF0E2138);
  static const Color inkSoft = Color(0xFF43526A);
  static const Color inkMuted = Color(0xFF7A8493);

  // Navy structural
  static const Color navy = Color(0xFF143C5C);
  static const Color navyDeep = Color(0xFF0B233A);
  static const Color hero1 = Color(0xFF061521);
  static const Color hero2 = Color(0xFF092034);
  static const Color hero3 = Color(0xFF0B3340);
  static const Color hero4 = Color(0xFF0A2A29);

  // Emerald brand spark
  static const Color green = Color(0xFF1FA565);
  static const Color greenDeep = Color(0xFF16804B);
  static const Color greenBright = Color(0xFF38B96A);
  static const Color greenSoft = Color(0xFFC9E9D8);

  // Aliases used across the app (kept stable so feature code is untouched)
  static const Color primary = green;
  static const Color primaryDark = greenDeep;
  static const Color accent = green;
  static const Color background = paper;
  static const Color textPrimary = ink;
  static const Color textSecondary = inkSoft;
  static const Color textMuted = inkMuted;
  static const Color cardBorder = Color(0x1A143C5C); // rgba(20,60,92,.10)
  static const Color cardBorderStrong = Color(0x2E143C5C); // .18

  // Sentiment
  static const Color positive = Color(0xFF1FA565);
  static const Color neutral = Color(0xFF64748B);
  static const Color negative = Color(0xFFDC2626);
  static const Color atRisk = Color(0xFFEA580C);

  // Gradients
  static const List<Color> brandGradient = <Color>[Color(0xFF27B978), Color(0xFF0F7A47)];
  static const List<Color> logoGradient = <Color>[greenBright, greenDeep];
  static const List<Color> heroGradient = <Color>[hero1, hero2, hero3, hero4];
  static const List<Color> splashGradient = <Color>[hero1, hero2, hero4];

  // Glows / shadows
  static const Color greenGlow = Color(0x731FA565); // rgba(31,165,101,.45)
  static const Color greenHalo = Color(0x2E1FA565); // rgba(31,165,101,.18)
  static const Color navyShadow = Color(0x8C143C5C); // rgba(20,60,92,.55)

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
