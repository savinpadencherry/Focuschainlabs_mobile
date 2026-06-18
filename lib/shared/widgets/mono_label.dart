import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// The site's signature "eyebrow": an uppercase, wide-tracked mono label with a
/// small leading marker. Sits above headings to give a technical, premium feel.
class MonoLabel extends StatelessWidget {
  const MonoLabel(
    this.text, {
    super.key,
    this.color = AppColors.green,
    this.onDark = false,
  });

  final String text;
  final Color color;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final Color c = onDark ? AppColors.greenBright : color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(text.toUpperCase(), style: AppTypography.mono(color: c)),
      ],
    );
  }
}
