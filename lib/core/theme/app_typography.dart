import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography from the Secona brand guidelines: Fraunces for display and
/// headings, Inter for body, JetBrains Mono for the technical "eyebrow" labels.
///
/// Fraunces is a serif, and serif headings on a phone need less negative
/// tracking than the grotesque they replace — the letterforms already carry
/// the weight. The tightening below is roughly half what the old Inter Tight
/// headings used for that reason.
///
/// google_fonts falls back to the platform font when a web font cannot be
/// fetched, so a first launch on a bad connection renders in the system face
/// rather than not at all.
abstract final class AppTypography {
  static TextTheme textTheme(TextTheme base) {
    final TextTheme display = GoogleFonts.frauncesTextTheme(base);
    final TextTheme body = GoogleFonts.interTextTheme(base);

    return base.copyWith(
      displayLarge: display.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.9,
        color: AppColors.ink,
      ),
      displayMedium: display.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: AppColors.ink,
      ),
      displaySmall: display.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
        color: AppColors.ink,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.ink,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.35,
        color: AppColors.ink,
      ),
      titleLarge: display.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
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
