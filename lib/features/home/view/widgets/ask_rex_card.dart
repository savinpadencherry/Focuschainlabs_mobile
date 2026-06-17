import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../lookup/view/lookup_page.dart';

/// The headline lookup entry point (F1). A bold gradient panel that opens the
/// conversational lookup.
class AskRexCard extends StatelessWidget {
  const AskRexCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => LookupPage.open(context),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.heroGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.32),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            ),
            const SizedBox(height: 26),
            const Text(
              AppStrings.askRexTitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            AppSpacing.vGapSm,
            Text(
              AppStrings.askRexBody,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.45,
                fontSize: 15,
              ),
            ),
            AppSpacing.vGapLg,
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
              onPressed: () => LookupPage.open(context),
              icon: const Icon(Icons.search_rounded),
              label: const Text(AppStrings.startLookup),
            ),
          ],
        ),
      ),
    );
  }
}
