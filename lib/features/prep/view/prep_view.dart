import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/get.dart';
import '../../../core/models/client_brief.dart';
import '../../../core/models/crm.dart';
import '../../../core/services/ai/ai_service.dart';
import '../../../core/services/crm/leads_crm_service.dart';
import '../../../core/services/navigator_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/mono_label.dart';
import '../../capture/view/conversation_view.dart';
import '../bloc/prep_cubit.dart';

/// "Prep me" mode: Rex briefs the rep before a call, grounded in the client's
/// recent CRM history and open-deal info, then offers to jump straight into a
/// conversation to log the outcome afterwards.
class PrepView extends StatelessWidget {
  const PrepView({super.key, required this.clientName});

  final String clientName;

  static Future<void> open(BuildContext context, String clientName) {
    return Navigator.of(context).push<void>(
      AppPageRoute<void>(
        BlocProvider<PrepCubit>(
          create: (_) => PrepCubit(
            ai: app<AiService>(),
            crm: app<LeadsCrmService>(),
            clientName: clientName,
          )..load(),
          child: PrepView(clientName: clientName),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: <Widget>[
            const Text('Prep with Rex'),
            const SizedBox(width: 10),
            const MonoLabel('brief'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ConversationView.open(context),
        icon: const Icon(Icons.mic_rounded),
        label: const Text('Talk to Rex'),
      ),
      body: SafeArea(
        top: false,
        child: ContentBounds(
          maxWidth: Breakpoints.readableMaxWidth,
          child: BlocBuilder<PrepCubit, PrepState>(
            builder: (BuildContext context, PrepState state) {
              switch (state.status) {
                case PrepStatus.loading:
                  return _Loading(clientName: clientName);
                case PrepStatus.error:
                  return _Error(
                    message: state.message ?? 'Something went wrong.',
                    onRetry: () => context.read<PrepCubit>().load(),
                  );
                case PrepStatus.ready:
                  return _Brief(
                    clientName: clientName,
                    brief: state.brief!,
                    contact: state.contact,
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.clientName});

  final String clientName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          AppSpacing.vGapLg,
          Text(
            'Rex is reading $clientName’s history…',
            style: const TextStyle(color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline_rounded,
                size: 40, color: AppColors.atRisk),
            AppSpacing.vGapMd,
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.inkSoft)),
            AppSpacing.vGapLg,
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Brief extends StatelessWidget {
  const _Brief({
    required this.clientName,
    required this.brief,
    this.contact,
  });

  final String clientName;
  final ClientBrief brief;
  final CrmContact? contact;

  String? get _dealLine {
    final CrmContact? c = contact;
    if (c == null) return null;
    final List<String> parts = <String>[
      if (c.value.trim().isNotEmpty) c.value.trim(),
      if (c.dealStatus.trim().isNotEmpty)
        c.dealStatus.trim()
      else if (c.status.trim().isNotEmpty)
        c.status.trim(),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final String? deal = _dealLine;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: <Widget>[
        const MonoLabel('Pre-call brief'),
        AppSpacing.vGapMd,
        Text(
          clientName,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
        ),
        if (deal != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(deal,
              style: const TextStyle(
                  color: AppColors.green, fontWeight: FontWeight.w600)),
        ],
        AppSpacing.vGapLg,
        _Headline(text: brief.headline),
        if (brief.opener.trim().isNotEmpty) ...<Widget>[
          AppSpacing.vGapLg,
          _Section(
            icon: Icons.waving_hand_outlined,
            title: 'Open with',
            child: Text(
              brief.opener,
              style: const TextStyle(
                  height: 1.5, fontStyle: FontStyle.italic, color: AppColors.ink),
            ),
          ),
        ],
        if (brief.talkingPoints.isNotEmpty) ...<Widget>[
          AppSpacing.vGapLg,
          _Section(
            icon: Icons.forum_outlined,
            title: 'Talking points',
            child: _Bullets(items: brief.talkingPoints),
          ),
        ],
        if (brief.thingsToConfirm.isNotEmpty) ...<Widget>[
          AppSpacing.vGapLg,
          _Section(
            icon: Icons.fact_check_outlined,
            title: 'Confirm on the call',
            child: _Bullets(items: brief.thingsToConfirm, marker: Icons.help_outline_rounded),
          ),
        ],
        if (brief.risks.isNotEmpty) ...<Widget>[
          AppSpacing.vGapLg,
          _Section(
            icon: Icons.warning_amber_rounded,
            title: 'Watch out for',
            accent: AppColors.atRisk,
            child: _Bullets(
              items: brief.risks,
              marker: Icons.priority_high_rounded,
              color: AppColors.atRisk,
            ),
          ),
        ],
      ]
          .animate(interval: 70.ms)
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.06, curve: Curves.easeOut),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.heroGradient),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          height: 1.45,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
    this.accent = AppColors.green,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: accent,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          child,
        ],
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets({
    required this.items,
    this.marker = Icons.check_circle_outline_rounded,
    this.color = AppColors.green,
  });

  final List<String> items;
  final IconData marker;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final String item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(marker, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(item,
                      style: const TextStyle(height: 1.4, fontSize: 14.5)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
