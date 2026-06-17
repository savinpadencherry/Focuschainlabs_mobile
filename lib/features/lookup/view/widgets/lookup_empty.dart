import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/rex_logo.dart';

/// Welcome + suggestion chips shown before the first lookup question.
class LookupEmpty extends StatelessWidget {
  const LookupEmpty({super.key, required this.onSuggestion});

  final ValueChanged<String> onSuggestion;

  static const List<String> _suggestions = <String>[
    'What’s the latest on Acme?',
    'What’s our configurator scope and price band?',
    'How do pilots work?',
    'Show me Northstar’s deal',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      children: <Widget>[
        Center(
          child: const RexLogo(size: 72).animate().scale(
                duration: 450.ms,
                curve: Curves.easeOutBack,
              ),
        ),
        AppSpacing.vGapXl,
        Text(
          'Ask anything about your\nclients or our offering',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ).animate().fadeIn(delay: 150.ms),
        AppSpacing.vGapSm,
        Text(
          'By voice or text. Answers are grounded in your org’s data and cite their source.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ).animate().fadeIn(delay: 250.ms),
        AppSpacing.vGapXxl,
        ..._suggestions.asMap().entries.map((MapEntry<int, String> e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _SuggestionChip(
              text: e.value,
              onTap: () => onSuggestion(e.value),
            ).animate().fadeIn(delay: (300 + e.key * 80).ms).slideY(begin: 0.2),
          );
        }),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: <Widget>[
              const Icon(Icons.bolt_rounded, size: 18, color: AppColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
              ),
              const Icon(Icons.north_east_rounded,
                  size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
