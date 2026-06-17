import 'package:flutter/material.dart';

/// Central colour palette for Mr. Rex.
///
/// The brand is a deep teal ("rainforest") with a warm amber accent — a nod to
/// the friendly T-Rex mascot. All UI colour decisions should reference this
/// class rather than hard-coding hex values, so re-theming stays a one-file job.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF0C4F49);
  static const Color primaryDeep = Color(0xFF0A3B36);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color accent = Color(0xFFF59E0B); // warm amber
  static const Color accentSoft = Color(0xFFFCD9A0);

  // Surfaces
  static const Color background = Color(0xFFF4F7F6);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFEAF1EF);
  static const Color cardBorder = Color(0xFFE5ECE9);

  // Text
  static const Color textPrimary = Color(0xFF0E1A18);
  static const Color textSecondary = Color(0xFF66706D);
  static const Color textMuted = Color(0xFF9AA4A1);

  // Semantic / sentiment (maps to extraction schema sentiment values)
  static const Color positive = Color(0xFF16A34A);
  static const Color neutral = Color(0xFF64748B);
  static const Color negative = Color(0xFFDC2626);
  static const Color atRisk = Color(0xFFEA580C);

  // Gradients
  static const List<Color> brandGradient = <Color>[primary, primaryDark];
  static const List<Color> heroGradient = <Color>[Color(0xFF0F766E), Color(0xFF115E59)];
  static const List<Color> logoGradient = <Color>[primaryLight, primary];
  static const List<Color> splashGradient = <Color>[primary, primaryDeep];

  /// Sentiment value (from the Claude extraction schema) → colour.
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
