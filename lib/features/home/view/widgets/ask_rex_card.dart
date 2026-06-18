import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/hero_panel.dart';
import '../../../../shared/widgets/mono_label.dart';
import '../../../lookup/view/lookup_page.dart';

/// The headline lookup entry point (F1), rendered as the website's dark hero
/// panel with an emerald glow, mono eyebrow and a pill CTA.
class AskRexCard extends StatelessWidget {
  const AskRexCard({super.key});

  @override
  Widget build(BuildContext context) {
    return HeroPanel(
      onTap: () => LookupPage.open(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const MonoLabel('Ask Rex · grounded in your data', onDark: true),
          const SizedBox(height: 18),
          Text(
            'Every client fact,\nin seconds.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  height: 1.05,
                ),
          ),
          AppSpacing.vGapSm,
          Text(
            'Clients, deals, follow-ups and product knowledge — by voice or tap.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.5,
              fontSize: 14.5,
            ),
          ),
          AppSpacing.vGapLg,
          _StartPill(onTap: () => LookupPage.open(context)),
        ],
      ),
    );
  }
}

class _StartPill extends StatelessWidget {
  const _StartPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.brandGradient),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: AppColors.greenGlow, blurRadius: 18, offset: Offset(0, 6)),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.search_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Start a lookup',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
