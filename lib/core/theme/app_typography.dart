import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typographic scale built on Plus Jakarta Sans (display/headings) and Inter
/// (body). google_fonts gracefully falls back to the platform font if the web
/// font cannot be fetched, so the app still renders cleanly offline.
abstract final class AppTypography {
  static TextTheme textTheme(TextTheme base) {
    final TextTheme display = GoogleFonts.plusJakartaSansTextTheme(base);
    final TextTheme body = GoogleFonts.interTextTheme(base);

    return base.copyWith(
      displayLarge: display.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.6,
        color: AppColors.textPrimary,
      ),
      displayMedium: display.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.4,
        color: AppColors.textPrimary,
      ),
      displaySmall: display.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: AppColors.textPrimary,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: AppColors.textPrimary,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      ),
      titleLarge: display.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        height: 1.5,
        color: AppColors.textPrimary,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        height: 1.45,
        color: AppColors.textSecondary,
      ),
      bodySmall: body.bodySmall?.copyWith(
        color: AppColors.textMuted,
      ),
      labelLarge: body.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}
