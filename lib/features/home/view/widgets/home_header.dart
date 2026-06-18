import 'package:flutter/material.dart';

import '../../../../core/models/user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/mono_label.dart';
import '../../../../shared/widgets/rex_logo.dart';

/// Greeting row: brand mark, time-aware mono eyebrow + headline, and the
/// signed-in user's avatar.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final String name = user?.name.split(' ').first ?? 'there';
    return Row(
      children: <Widget>[
        const RexLogo(size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MonoLabel('${Formatters.greeting(DateTime.now())}, $name'),
              const SizedBox(height: 6),
              const Text(
                'Ready to sell smarter?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        _Avatar(user: user),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: AppColors.logoGradient),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 21,
        backgroundColor: AppColors.surface,
        child: Text(
          user?.initials ?? '🦖',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
