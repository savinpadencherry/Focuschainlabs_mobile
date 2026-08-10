import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/get.dart';
import '../../../core/models/listing.dart';
import '../../../core/repository/crm_repository.dart';
import '../../../core/services/api/identity_cache.dart';
import '../../../core/services/api/secona_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/crm_chips.dart';
import '../../../shared/widgets/web_view_screen.dart';
import '../../auth/bloc/auth_bloc.dart';

/// Identity, tenant, and the way out.
///
/// The identity shown here is the CRM's answer to "who are you", not Google's.
/// They can differ — a signed-in Google account that is not on the invite list
/// is exactly the case worth surfacing clearly, because the fix (sign in with
/// the work account) is not obvious from a permission error.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Me? _me;
  String _error = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final Me me = await app<CrmRepository>().me();
      IdentityCache.current = me;
      if (mounted) setState(() => _me = me);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.paper,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: ContentBounds(
          maxWidth: Breakpoints.readableMaxWidth,
          child: RefreshIndicator(
            color: AppColors.green,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: <Widget>[
                _Identity(me: _me, loading: _loading),
                if (_error.isNotEmpty) ...<Widget>[
                  AppSpacing.vGapLg,
                  _AccessProblem(message: _error, onRetry: _load),
                ],
                if (_me != null) ...<Widget>[
                  AppSpacing.vGapLg,
                  _OrgCard(me: _me!),
                ],
                AppSpacing.vGapLg,
                const _ConnectionCard(),
                if (AppConfig.hasCrmWeb) ...<Widget>[
                  AppSpacing.vGapLg,
                  const _OpenWebApp(),
                ],
                AppSpacing.vGapXxl,
                const _SignOutButton(),
                AppSpacing.vGapLg,
                Center(
                  child: Text(
                    '${AppConstants.appName} · v${AppConstants.appVersion}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.me, required this.loading});

  final Me? me;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final String name = me?.name ?? '';
    final String email = me?.email ??
        context.select((AuthBloc b) => b.state.user?.email) ??
        '';

    return Row(
      children: <Widget>[
        Container(
          width: 62,
          height: 62,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: AppColors.logoGradient),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            me?.initials ?? '·',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name.isNotEmpty ? name : (loading ? 'Loading…' : 'Signed in'),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (email.isNotEmpty)
                Text(email, style: Theme.of(context).textTheme.bodyMedium),
              if (me != null) ...<Widget>[
                const SizedBox(height: 6),
                ChipRow(
                  children: <Widget>[
                    TagChip(
                      me!.role,
                      color: AppColors.green,
                      icon: Icons.badge_outlined,
                    ),
                    if (me!.canDistributeListings)
                      const TagChip(
                        'Distributes listings',
                        color: AppColors.navy,
                        icon: Icons.share_outlined,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Signed in with Google, but the CRM will not have them.
class _AccessProblem extends StatelessWidget {
  const _AccessProblem({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.negative.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.negative.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.lock_outline_rounded,
                  size: 18, color: AppColors.negative),
              const SizedBox(width: 8),
              Text(
                'No CRM access',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(message),
          AppSpacing.vGapSm,
          Text(
            'If you signed in with a personal account, sign out and use your '
            'work address.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          AppSpacing.vGapSm,
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onRetry, child: const Text('Retry')),
          ),
        ],
      ),
    );
  }
}

class _OrgCard extends StatelessWidget {
  const _OrgCard({required this.me});

  final Me me;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.business_rounded, color: AppColors.navy),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  me.organizationName.isNotEmpty
                      ? me.organizationName
                      : me.organizationId,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Everything you do here is scoped to this organisation.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Whether this build can reach the CRM at all — the first thing to check when
/// every surface is empty.
class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard();

  @override
  Widget build(BuildContext context) {
    final bool configured = AppConfig.hasApi;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            configured ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            color: configured ? AppColors.green : AppColors.negative,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  configured ? 'Connected to the CRM' : 'No CRM address',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  configured
                      ? 'Live — the same database as the web app.'
                      : 'This build was made without an API address. Reinstall the latest APK.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The desktop surfaces the phone deliberately does not reimplement.
class _OpenWebApp extends StatelessWidget {
  const _OpenWebApp();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => WebViewScreen.open(
        context,
        url: AppConfig.crmWebUrl,
        title: 'Secona web',
      ),
      icon: const Icon(Icons.open_in_new_rounded, size: 18),
      label: const Text('Open the full web app'),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.negative),
        onPressed: () {
          // Profile is a pushed route, so the login screen would otherwise
          // appear *underneath* it and the user would still be looking at
          // their own profile after signing out. Drop back to the gate first,
          // and forget the cached identity so the next person to sign in does
          // not inherit these initials.
          IdentityCache.clear();
          Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
          context.read<AuthBloc>().add(const AuthSignOutRequested());
        },
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Sign out'),
      ),
    );
  }
}
