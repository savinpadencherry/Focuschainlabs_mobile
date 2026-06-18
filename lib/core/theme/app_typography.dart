import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography matching the website: Inter Tight for display/headings, Inter for
/// body, and JetBrains Mono for technical "eyebrow" labels. google_fonts falls
/// back to the platform font if the web font can't be fetched (offline-safe).
abstract final class AppTypography {
  static TextTheme textTheme(TextTheme base) {
    final TextTheme display = GoogleFonts.interTightTextTheme(base);
    final TextTheme body = GoogleFonts.interTextTheme(base);

    return base.copyWith(
      displayLarge: display.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.8,
        color: AppColors.ink,
      ),
      displayMedium: display.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        color: AppColors.ink,
      ),
      displaySmall: display.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.3,
        color: AppColors.ink,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.9,
        color: AppColors.ink,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: AppColors.ink,
      ),
      titleLarge: display.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: AppColors.ink,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      bodyLarge: body.bodyLarge?.copyWith(height: 1.6, color: AppColors.ink),
      bodyMedium: body.bodyMedium?.copyWith(height: 1.55, color: AppColors.inkSoft),
      bodySmall: body.bodySmall?.copyWith(color: AppColors.inkMuted),
      labelLarge: body.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }

  /// Mono "eyebrow" label — uppercase, wide-tracked, used above headings to
  /// echo the site's technical, premium feel.
  static TextStyle mono({
    double size = 11,
    Color color = AppColors.green,
    FontWeight weight = FontWeight.w600,
    double letterSpacing = 2.2,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: letterSpacing,
    );
  }
}
