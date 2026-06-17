import 'package:flutter/material.dart';

import '../../../../core/models/user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/rex_logo.dart';

/// Greeting row: brand mark, time-aware greeting and a notifications affordance.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final String name = user?.name.split(' ').first ?? 'there';
    return Row(
      children: <Widget>[
        const RexLogo(size: 50),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${Formatters.greeting(DateTime.now())}, $name',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const Text(
                'Ready to sell smarter?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}
