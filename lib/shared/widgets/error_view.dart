import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// What a surface shows when it could not reach the CRM.
///
/// Says what failed and offers the one useful action. It never falls back to
/// cached or sample data: a rep cannot tell stale data from live data until
/// they act on it, and acting on it is the expensive part.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'Could not reach the CRM',
  });

  final String message;
  final String title;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.negative.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 34,
                color: AppColors.negative,
              ),
            ),
            AppSpacing.vGapLg,
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            AppSpacing.vGapSm,
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...<Widget>[
              AppSpacing.vGapLg,
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A thin progress line for a refresh that is happening over existing content.
///
/// Replacing a loaded board with a spinner on every refresh makes the app feel
/// slower than it is and hides the data the user is still reading.
class RefreshBar extends StatelessWidget {
  const RefreshBar({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: visible
          ? const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: AppColors.green,
            )
          : null,
    );
  }
}
