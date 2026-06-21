import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/get.dart';
import '../../../core/models/client.dart';
import '../../../core/repository/client_repository.dart';
import '../../../core/services/navigator_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/sentiment_chip.dart';
import '../../capture/view/conversation_view.dart';
import '../../prep/view/prep_view.dart';
import 'widgets/client_sections.dart';

/// Full client 360 (F1): contacts, deals, interaction timeline, emails and
/// pending follow-ups — everything a rep needs before a call, in one scroll.
class ClientDetailView extends StatelessWidget {
  const ClientDetailView({super.key, required this.clientId});

  final String clientId;

  static Future<void> open(BuildContext context, String clientId) {
    return Navigator.of(context)
        .push<void>(AppPageRoute<void>(ClientDetailView(clientId: clientId)));
  }

  @override
  Widget build(BuildContext context) {
    final Client? client = app<ClientRepository>().byId(clientId);
    if (client == null) {
      return const Scaffold(body: Center(child: Text('Client not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(client.name),
        actions: <Widget>[
          IconButton(
            tooltip: 'Prep me for a call',
            onPressed: () => PrepView.open(context, client.name),
            icon: const Icon(Icons.auto_awesome_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ConversationView.open(context),
        icon: const Icon(Icons.mic_rounded),
        label: const Text('Log update'),
      ),
      body: SafeArea(
        top: false,
        child: ContentBounds(
          maxWidth: Breakpoints.readableMaxWidth,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: <Widget>[
              _Header(client: client),
              AppSpacing.vGapXl,
              if (client.deals.isNotEmpty) ...<Widget>[
                DealsSection(deals: client.deals),
                AppSpacing.vGapXl,
              ],
              if (client.pendingFollowUps.isNotEmpty) ...<Widget>[
                FollowUpsSection(followUps: client.pendingFollowUps),
                AppSpacing.vGapXl,
              ],
              if (client.contacts.isNotEmpty) ...<Widget>[
                ContactsSection(contacts: client.contacts),
                AppSpacing.vGapXl,
              ],
              if (client.interactions.isNotEmpty) ...<Widget>[
                TimelineSection(interactions: client.interactions),
                AppSpacing.vGapXl,
              ],
              if (client.recentEmailSubjects.isNotEmpty)
                EmailsSection(subjects: client.recentEmailSubjects),
            ].animate(interval: 60.ms).fadeIn(duration: 320.ms).slideY(begin: 0.06),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.logoGradient),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          alignment: Alignment.center,
          child: Text(
            client.initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 26,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(client.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                '${client.industry} · Owner ${client.owner}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              SentimentChip(sentiment: client.sentiment),
            ],
          ),
        ),
      ],
    );
  }
}
