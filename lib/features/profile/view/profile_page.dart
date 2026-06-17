import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/data/seed_data.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/user.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../auth/bloc/auth_bloc.dart';
import 'widgets/connections_card.dart';

/// Profile + connections surface (F9/F10): identity, org/role, integration
/// status and sign-out.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppUser? user = context.select((AuthBloc b) => b.state.user);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        top: false,
        child: ContentBounds(
          maxWidth: Breakpoints.readableMaxWidth,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: <Widget>[
              _Identity(user: user),
              AppSpacing.vGapXxl,
              ConnectionsCard(integrations: SeedData.integrations()),
              AppSpacing.vGapLg,
              _OrgCard(user: user),
              AppSpacing.vGapLg,
              _SignOutButton(),
              AppSpacing.vGapLg,
              Center(
                child: Text(
                  'Mr. Rex · v${AppConstants.appVersion}'
                  '${AppConstants.demoMode ? ' · demo mode' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ].animate(interval: 60.ms).fadeIn(duration: 320.ms).slideY(begin: 0.06),
          ),
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.logoGradient),
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            user?.initials ?? '🦖',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        AppSpacing.vGapLg,
        Text(user?.name ?? 'Guest', style: Theme.of(context).textTheme.titleLarge),
        AppSpacing.vGapXs,
        Text(
          '${user?.role.label ?? 'Sales rep'} · ${user?.orgName ?? AppConstants.companyName}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _OrgCard extends StatelessWidget {
  const _OrgCard({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.shield_outlined, color: AppColors.primary),
            title: const Text('Organisation & access',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${user?.orgName ?? '—'} · ${user?.role.label ?? '—'}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.lock_outline_rounded, color: AppColors.primary),
            title: Text('Data isolation',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('Row-level security · your org’s data only'),
            trailing: Icon(Icons.verified_user_outlined, color: AppColors.positive),
          ),
        ],
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () =>
            context.read<AuthBloc>().add(const AuthSignOutRequested()),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.negative,
          side: const BorderSide(color: Color(0xFFF3D2D2)),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Sign out'),
      ),
    );
  }
}
