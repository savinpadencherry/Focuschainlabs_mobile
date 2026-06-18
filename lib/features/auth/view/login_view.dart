import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/mono_label.dart';
import '../../../shared/widgets/rex_logo.dart';
import '../bloc/auth_bloc.dart';

/// Sign-in surface (F10). Renders a centred card on wide screens and a
/// full-bleed layout on phones.
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ContentBounds(
          maxWidth: Breakpoints.readableMaxWidth,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: context.isWide
                ? Center(child: SingleChildScrollView(child: _LoginContent()))
                : _LoginContent(),
          ),
        ),
      ),
    );
  }
}

class _LoginContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bool wide = context.isWide;
    return Column(
      mainAxisSize: wide ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const RexLogo(size: 60).animate().scale(
              duration: 450.ms,
              curve: Curves.easeOutBack,
            ),
        if (!wide) const Spacer(),
        SizedBox(height: wide ? 28 : 0),
        const MonoLabel('FocusChain Labs · Sales companion')
            .animate()
            .fadeIn(delay: 80.ms),
        AppSpacing.vGapMd,
        Text(
          AppStrings.welcomeTitle,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(height: 1.02),
        ).animate().fadeIn(delay: 120.ms).slideX(begin: -0.1),
        AppSpacing.vGapLg,
        Text(
          AppStrings.welcomeBody,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ).animate().fadeIn(delay: 200.ms),
        AppSpacing.vGapXl,
        const _FeatureStrip().animate().fadeIn(delay: 260.ms).slideY(begin: 0.15),
        if (!wide) const Spacer(),
        SizedBox(height: wide ? 28 : 0),
        _IsolationNote().animate().fadeIn(delay: 320.ms).slideY(begin: 0.2),
        AppSpacing.vGapXl,
        const _SignInButtons().animate().fadeIn(delay: 380.ms),
      ],
    );
  }
}

/// Three compact value props with the brand's mono/emerald styling.
class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip();

  static const List<(IconData, String)> _items = <(IconData, String)>[
    (Icons.bolt_rounded, 'Client context in seconds'),
    (Icons.mic_rounded, 'Update the CRM by voice'),
    (Icons.event_available_rounded, 'Follow-ups that never slip'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (final (IconData icon, String label) in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.green),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _IsolationNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.lock_outline_rounded, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(AppStrings.isolationNote, style: TextStyle(height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _SignInButtons extends StatelessWidget {
  const _SignInButtons();

  @override
  Widget build(BuildContext context) {
    final bool loading =
        context.select((AuthBloc b) => b.state.isLoading);
    return Column(
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: loading
                ? null
                : () => context.read<AuthBloc>().add(const AuthSignInRequested()),
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.login_rounded),
            label: Text(loading ? 'Signing in…' : AppStrings.continueGoogle),
          ),
        ),
        AppSpacing.vGapMd,
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: loading
                ? null
                : () => context.read<AuthBloc>().add(const AuthSignInRequested()),
            child: const Text(AppStrings.useWorkEmail),
          ),
        ),
      ],
    );
  }
}
