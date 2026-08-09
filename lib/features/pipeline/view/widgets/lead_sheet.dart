import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/pipeline.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/crm_chips.dart';
import '../../bloc/pipeline_bloc.dart';

/// The lead detail sheet: who they are, what they want, what happened, and the
/// four things a rep actually does next.
///
/// Every write here is confirmed before it happens and shows the stored record
/// afterwards — the timeline reloads from the server rather than optimistically
/// appending, so what is on screen is what is in the database.
class LeadSheet extends StatelessWidget {
  const LeadSheet({super.key});

  /// Opens the sheet for [id], loading it through the bloc.
  static void open(BuildContext context, String id) {
    final PipelineBloc bloc = context.read<PipelineBloc>()
      ..add(PipelineLeadOpened(id));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider<PipelineBloc>.value(
        value: bloc,
        child: const LeadSheet(),
      ),
    ).whenComplete(() => bloc.add(const PipelineLeadClosed()));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (BuildContext context, ScrollController controller) {
        return BlocBuilder<PipelineBloc, PipelineState>(
          builder: (BuildContext context, PipelineState state) {
            final Lead? lead = state.openLead;
            if (lead == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.green),
                ),
              );
            }
            return _Body(lead: lead, controller: controller, busy: state.leadBusy);
          },
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.lead, required this.controller, required this.busy});

  final Lead lead;
  final ScrollController controller;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      children: <Widget>[
        const SizedBox(height: 10),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.cardBorderStrong,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (busy)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 2,
              child: LinearProgressIndicator(minHeight: 2, color: AppColors.green),
            ),
          ),
        Expanded(
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: <Widget>[
              Text(
                lead.title,
                style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (lead.subtitle.isNotEmpty) ...<Widget>[
                const SizedBox(height: 3),
                Text(lead.subtitle, style: text.bodyMedium),
              ],
              AppSpacing.vGapMd,
              ChipRow(
                children: <Widget>[
                  StageChip(lead.stage),
                  if (lead.needsAttention) RiskChip(lead),
                  if (lead.moneyLabel.isNotEmpty)
                    TagChip(
                      lead.moneyLabel,
                      color: AppColors.green,
                      icon: Icons.currency_rupee_rounded,
                    ),
                ],
              ),
              AppSpacing.vGapLg,
              _ActionStrip(lead: lead),
              AppSpacing.vGapLg,
              _StageMover(lead: lead),
              AppSpacing.vGapLg,
              _Facts(lead: lead),
              if (lead.riskReasons.isNotEmpty) ...<Widget>[
                AppSpacing.vGapLg,
                _WhyThisScore(lead: lead),
              ],
              AppSpacing.vGapLg,
              _Timeline(lead: lead),
            ],
          ),
        ),
      ],
    );
  }
}

/// WhatsApp, call, email, log — the things a rep does from a lead.
///
/// These leave the app on purpose: the phone already has the right tools for
/// three of them, and reimplementing a dialler would be worse than launching one.
class _ActionStrip extends StatelessWidget {
  const _ActionStrip({required this.lead});

  final Lead lead;

  Future<void> _launch(BuildContext context, Uri uri) async {
    final bool ok = await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nothing on this phone can open ${uri.scheme}.')),
      );
    }
  }

  /// Digits only, so "+91 84229 78854" becomes a dialable number.
  String get _phone => lead.phone.replaceAll(RegExp(r'[^0-9+]'), '');

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (_phone.isNotEmpty) ...<Widget>[
          Expanded(
            child: _ActionButton(
              icon: Icons.chat_rounded,
              label: 'WhatsApp',
              color: const Color(0xFF25D366),
              onTap: () => _launch(
                context,
                Uri.parse('https://wa.me/${_phone.replaceAll('+', '')}'),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              icon: Icons.call_rounded,
              label: 'Call',
              color: AppColors.navy,
              onTap: () => _launch(context, Uri.parse('tel:$_phone')),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (lead.email.isNotEmpty) ...<Widget>[
          Expanded(
            child: _ActionButton(
              icon: Icons.mail_outline_rounded,
              label: 'Email',
              color: AppColors.inkSoft,
              onTap: () => _launch(context, Uri.parse('mailto:${lead.email}')),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: _ActionButton(
            icon: Icons.edit_note_rounded,
            label: 'Log',
            color: AppColors.green,
            onTap: () => _LogNoteDialog.open(context, lead),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 19, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Moving a stage is a write, so it asks first and names the move.
class _StageMover extends StatelessWidget {
  const _StageMover({required this.lead});

  final Lead lead;

  Future<void> _move(BuildContext context, Stage to) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Move this lead?'),
        content: Text(
          '${lead.title} moves from ${lead.stage.label} to ${to.label}. '
          'Everyone on the web app sees this straight away.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Move to ${to.label}'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<PipelineBloc>().add(PipelineStageChanged(lead.id, to));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Stage', style: Theme.of(context).textTheme.labelLarge),
        AppSpacing.vGapSm,
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final Stage s in Stage.values)
              if (s == lead.stage)
                StageChip(s)
              else
                TagChip(
                  s.label,
                  color: stageColor(s),
                  filled: false,
                  onTap: () => _move(context, s),
                ),
          ],
        ),
      ],
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> rows = <(String, String)>[
      if (lead.phone.isNotEmpty) ('Phone', lead.phone),
      if (lead.email.isNotEmpty) ('Email', lead.email),
      if (lead.budget.isNotEmpty) ('Budget', lead.budget),
      if (lead.requirement.isNotEmpty) ('Looking for', lead.requirement),
      if (lead.locality.isNotEmpty) ('Locality', lead.locality),
      if (lead.source.isNotEmpty) ('Source', lead.source),
      if (lead.owner.isNotEmpty) ('Owner', lead.owner),
      if (lead.nextFollowUp.isNotEmpty) ('Next follow-up', lead.nextFollowUp),
    ];
    if (rows.isEmpty && lead.notes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Details', style: Theme.of(context).textTheme.labelLarge),
        AppSpacing.vGapSm,
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: <Widget>[
              for (int i = 0; i < rows.length; i++) ...<Widget>[
                if (i > 0) const Divider(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 108,
                      child: Text(
                        rows[i].$1,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        rows[i].$2,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
              if (lead.notes.isNotEmpty) ...<Widget>[
                const Divider(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    lead.notes,
                    style: TextStyle(
                      fontStyle:
                          lead.notesArePrivate ? FontStyle.italic : FontStyle.normal,
                      color: lead.notesArePrivate
                          ? AppColors.inkMuted
                          : AppColors.ink,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The score's reasons, so a number on a card is checkable rather than magic.
class _WhyThisScore extends StatelessWidget {
  const _WhyThisScore({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Why score ${lead.score}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        AppSpacing.vGapSm,
        for (final String reason in lead.riskReasons)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.circle, size: 6, color: AppColors.atRisk),
                const SizedBox(width: 8),
                Expanded(child: Text(reason)),
              ],
            ),
          ),
        for (final ScoreFactor f in lead.topFactors)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.circle, size: 6, color: AppColors.green),
                const SizedBox(width: 8),
                Expanded(child: Text(f.reason)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Timeline', style: Theme.of(context).textTheme.labelLarge),
        AppSpacing.vGapSm,
        if (lead.activities.isEmpty)
          Text(
            'Nothing logged yet. Tap Log to put the first note on the record.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          for (final LeadActivity a in lead.activities)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          a.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (a.note.isNotEmpty) Text(a.note),
                        if (a.createdAt != null)
                          Text(
                            _when(a.createdAt!),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  static String _when(DateTime dt) {
    final Duration ago = DateTime.now().difference(dt.toLocal());
    if (ago.inMinutes < 60) return '${ago.inMinutes}m ago';
    if (ago.inHours < 24) return '${ago.inHours}h ago';
    if (ago.inDays < 30) return '${ago.inDays}d ago';
    return '${dt.toLocal()}'.split(' ').first;
  }
}

/// Compose a note, see it, then confirm. Ona's rule applies to the rep too:
/// nothing is written until a person presses the button.
class _LogNoteDialog extends StatefulWidget {
  const _LogNoteDialog({required this.lead});

  final Lead lead;

  static void open(BuildContext context, Lead lead) {
    final PipelineBloc bloc = context.read<PipelineBloc>();
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider<PipelineBloc>.value(
        value: bloc,
        child: _LogNoteDialog(lead: lead),
      ),
    );
  }

  @override
  State<_LogNoteDialog> createState() => _LogNoteDialogState();
}

class _LogNoteDialogState extends State<_LogNoteDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Log on ${widget.lead.title}'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'What happened? e.g. “Site visit done, wants a revised quote.”',
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final String note = _controller.text.trim();
            if (note.isEmpty) return;
            context
                .read<PipelineBloc>()
                .add(PipelineNoteLogged(widget.lead.id, note));
            Navigator.pop(context);
          },
          child: const Text('Log it'),
        ),
      ],
    );
  }
}
