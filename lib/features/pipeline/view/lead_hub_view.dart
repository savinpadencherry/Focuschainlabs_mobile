import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/get.dart';
import '../../../core/models/lead_chat.dart';
import '../../../core/repository/crm_repository.dart';
import '../../../core/services/api/secona_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/crm_chips.dart';
import '../../../shared/widgets/error_view.dart';
import '../bloc/pipeline_bloc.dart';
import 'lead_chat_view.dart';
import 'lead_detail_view.dart';
import 'widgets/lead_brief_tile.dart';

/// What opens when you tap a lead: the brief, then the two ways in.
///
/// A lead is two different jobs — reading and correcting the record, or
/// thinking out loud about what to do next — and they want different screens.
/// Landing straight in either one makes the other feel buried, so this is the
/// fork, with the brief on it so the fork itself is useful rather than a menu
/// you pass through.
class LeadHubView extends StatefulWidget {
  const LeadHubView({super.key, required this.leadId});

  final String leadId;

  static Future<void> open(BuildContext context, String leadId) {
    final PipelineBloc bloc = context.read<PipelineBloc>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<PipelineBloc>.value(
          value: bloc,
          child: LeadHubView(leadId: leadId),
        ),
      ),
    );
  }

  @override
  State<LeadHubView> createState() => _LeadHubViewState();
}

class _LeadHubViewState extends State<LeadHubView> {
  LeadChatThread? _thread;
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
      final LeadChatThread t =
          await app<CrmRepository>().leadThread(widget.leadId);
      if (mounted) setState(() => _thread = t);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LeadChatThread? t = _thread;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        title: Text(t?.lead.title ?? 'Lead'),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: _load,
          child: _error.isNotEmpty
              ? ErrorView(message: _error, onRetry: _load)
              : ContentBounds(
                  maxWidth: Breakpoints.readableMaxWidth,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    children: <Widget>[
                      if (t != null) _Identity(thread: t),
                      AppSpacing.vGapLg,
                      if (_loading && t == null)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(
                              color: AppColors.green,
                            ),
                          ),
                        )
                      else if (t != null) ...<Widget>[
                        LeadBriefTile(brief: t.brief)
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.1, curve: Curves.easeOutCubic),
                        AppSpacing.vGapXl,
                        _Choice(
                          icon: Icons.badge_outlined,
                          title: 'Open lead',
                          body: 'The full record — details, timeline, stage. '
                              'Editable.',
                          color: AppColors.iris,
                          onTap: () async {
                            await LeadDetailView.open(context, widget.leadId);
                            if (mounted) _load();
                          },
                        ),
                        AppSpacing.vGapMd,
                        _Choice(
                          icon: Icons.forum_outlined,
                          title: 'Open lead chat',
                          body: t.messages.isEmpty
                              ? 'Ask Ona about this lead — it answers from '
                                  'their record, not from guesses.'
                              : '${t.messages.length} message'
                                  '${t.messages.length == 1 ? '' : 's'} in this thread',
                          color: AppColors.green,
                          onTap: () async {
                            await LeadChatView.open(context, widget.leadId);
                            if (mounted) _load();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.thread});

  final LeadChatThread thread;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          thread.lead.title,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (thread.lead.subtitle.isNotEmpty)
          Text(thread.lead.subtitle,
              style: Theme.of(context).textTheme.bodyMedium),
        AppSpacing.vGapSm,
        ChipRow(
          children: <Widget>[
            StageChip(thread.lead.stage),
            if (thread.lead.needsAttention) RiskChip(thread.lead),
            if (thread.lead.moneyLabel.isNotEmpty)
              TagChip(
                thread.lead.moneyLabel,
                color: AppColors.green,
                icon: Icons.currency_rupee_rounded,
              ),
          ],
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(body, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.08);
  }
}
