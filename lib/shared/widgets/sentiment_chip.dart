import 'package:flutter/material.dart';

import '../../core/models/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// A small coloured pill that surfaces sentiment (positive/neutral/negative/
/// at-risk) consistently wherever a client or capture appears.
class SentimentChip extends StatelessWidget {
  const SentimentChip({super.key, required this.sentiment, this.compact = false});

  final Sentiment sentiment;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color color = AppColors.sentiment(sentiment.wire);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            sentiment.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
