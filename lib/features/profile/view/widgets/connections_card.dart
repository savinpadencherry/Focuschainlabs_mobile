import 'package:flutter/material.dart';

import '../../../../core/models/activity.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Lists the org's integrations and their connection status (F9: admin
/// connects CRM/calendar/task/email).
class ConnectionsCard extends StatelessWidget {
  const ConnectionsCard({super.key, required this.integrations});

  final List<Integration> integrations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Connections', style: Theme.of(context).textTheme.titleMedium),
        AppSpacing.vGapMd,
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: <Widget>[
              for (int i = 0; i < integrations.length; i++) ...<Widget>[
                if (i > 0) const Divider(height: 1),
                _IntegrationRow(integration: integrations[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _IntegrationRow extends StatelessWidget {
  const _IntegrationRow({required this.integration});

  final Integration integration;

  IconData get _icon {
    switch (integration.category) {
      case 'Calendar':
        return Icons.calendar_month_outlined;
      case 'CRM':
        return Icons.storage_outlined;
      case 'Task tool':
        return Icons.checklist_rounded;
      case 'Email':
        return Icons.mail_outline_rounded;
      default:
        return Icons.extension_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool connected = integration.status == ConnectionStatus.connected;
    return ListTile(
      leading: Icon(_icon, color: AppColors.primary),
      title: Text(integration.name,
          style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(integration.detail ?? integration.category),
      trailing: _StatusPill(status: integration.status),
      onTap: connected ? null : () {},
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final (String, Color) data = switch (status) {
      ConnectionStatus.connected => ('Connected', AppColors.positive),
      ConnectionStatus.pending => ('Connect', AppColors.accent),
      ConnectionStatus.error => ('Re-auth', AppColors.negative),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: data.$2.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        data.$1,
        style: TextStyle(
          color: data.$2,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
