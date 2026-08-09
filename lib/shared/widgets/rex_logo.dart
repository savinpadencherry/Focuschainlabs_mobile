import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// The Secona brand mark: a rounded gradient badge carrying the friendly
/// T-Rex mascot. Used in the splash, login, home header and app bars so the
/// brand reads consistently at every size. Pure-code (no image assets).
class RexLogo extends StatelessWidget {
  const RexLogo({
    super.key,
    this.size = 50,
    this.gradient = AppColors.logoGradient,
    this.glyphColor = Colors.white,
  });

  final double size;
  final List<Color> gradient;
  final Color glyphColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.34),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.35),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.16),
          ),
        ],
      ),
      alignment: Alignment.center,
      // The brand mark is the wordmark's "O" — one glyph, sized from the
      // wrapper, so the splash and the rail cannot drift apart.
      child: Text(
        'O',
        style: TextStyle(
          fontSize: size * 0.52,
          height: 1,
          fontWeight: FontWeight.w800,
          color: glyphColor,
        ),
      ),
    );
  }
}

/// Wordmark + tagline lockup for the splash / login hero.
class RexWordmark extends StatelessWidget {
  const RexWordmark({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final Color title = onDark ? Colors.white : AppColors.textPrimary;
    final Color sub = onDark ? Colors.white70 : AppColors.textSecondary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(color: title),
        ),
        AppSpacing.gapXs,
        Text(
          AppConstants.tagline,
          textAlign: TextAlign.center,
          style: TextStyle(color: sub, fontSize: 15),
        ),
      ],
    );
  }
}
