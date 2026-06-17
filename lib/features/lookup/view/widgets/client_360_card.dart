import 'package:flutter/material.dart';

import '../../../../core/get.dart';
import '../../../../core/models/client.dart';
import '../../../../core/repository/client_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/sentiment_chip.dart';
import '../../../client/view/client_detail_view.dart';

/// A compact "client 360" summary embedded under a lookup answer (F1).
class Client360Card extends StatelessWidget {
  const Client360Card({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    final Client? client = app<ClientRepository>().byId(clientId);
    if (client == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                child: Text(
                  client.initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      client.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      client.industry,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SentimentChip(sentiment: client.sentiment, compact: true),
            ],
          ),
          if (client.primaryDeal != null) ...<Widget>[
            const SizedBox(height: 12),
            _MetaRow(
              icon: Icons.trending_up_rounded,
              label: '${client.primaryDeal!.title} · ${client.primaryDeal!.stage.label}',
              trailing: client.primaryDeal!.value,
            ),
          ],
          if (client.pendingFollowUps.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            _MetaRow(
              icon: Icons.flag_outlined,
              label: client.pendingFollowUps.first,
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => ClientDetailView.open(context, client.id),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('View full profile'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label, this.trailing});

  final IconData icon;
  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
      ],
    );
  }
}
