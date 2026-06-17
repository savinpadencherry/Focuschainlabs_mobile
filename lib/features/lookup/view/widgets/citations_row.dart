import 'package:flutter/material.dart';

import '../../../../core/models/lookup.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Grounding chips under a Rex answer (F1: cite the source; nothing invented).
class CitationsRow extends StatelessWidget {
  const CitationsRow({super.key, required this.citations});

  final List<Citation> citations;

  IconData _icon(String type) {
    switch (type) {
      case 'Email':
        return Icons.mail_outline_rounded;
      case 'Product doc':
        return Icons.description_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: citations.map((Citation c) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(_icon(c.type), size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                c.label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
