import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/pipeline.dart';
import '../../../core/services/api/identity_cache.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/crm_chips.dart';
import '../bloc/pipeline_bloc.dart';
import 'widgets/lead_composer.dart';
import 'widgets/lead_edit_sheet.dart';

/// The full lead record: details, stage, timeline, and the actions on it.
///
/// A page rather than the bottom sheet this replaces. The sheet was fine for a
/// glance, but this is where a rep corrects a budget and reads a timeline, and
/// a draggable sheet fights both — it steals the scroll gesture and it cannot
/// hold a keyboard without covering the field being typed into.
class LeadDetailView extends StatelessWidget {
  const LeadDetailView({super.key, required this.leadId});

  final String leadId;

  static Future<void> open(BuildContext context, String leadId) {
    final PipelineBloc bloc = context.read<PipelineBloc>()
      ..add(PipelineLeadOpened(leadId));
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<PipelineBloc>.value(
          value: bloc,
          child: LeadDetailView(leadId: leadId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<PipelineBloc, PipelineState>(
          builder: (BuildContext context, PipelineState state) {
            final Lead? lead = state.openLead;
            if (lead == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.green),
              );
            }
            return Column(
              children: <Widget>[
                _TopBar(lead: lead),
                if (state.leadBusy)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: AppColors.green,
                    backgroundColor: Colors.transparent,
                  ),
                Expanded(
                  child: ContentBounds(
                    maxWidth: Breakpoints.readableMaxWidth,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      children: <Widget>[
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
                        if (lead.people.isNotEmpty) ...<Widget>[
                          _People(lead: lead),
                          AppSpacing.vGapLg,
                        ],
                        if (lead.riskReasons.isNotEmpty) ...<Widget>[
                          _WhyThisScore(lead: lead),
                          AppSpacing.vGapLg,
                        ],
                        _Timeline(lead: lead),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  lead.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                ),
                if (lead.subtitle.isNotEmpty)
                  Text(
                    lead.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          // Hidden rather than disabled when the server says this account may
          // not edit: a greyed-out button invites a tap and explains nothing.
          if (IdentityCache.access.canEditLeads)
            TextButton.icon(
              onPressed: () => LeadEditSheet.open(context, lead).then((Lead? l) {
                if (l != null && context.mounted) {
                  context.read<PipelineBloc>().add(PipelineLeadOpened(lead.id));
                  context.read<PipelineBloc>().add(const PipelineLoaded());
                }
              }),
              icon: const Icon(Icons.edit_outlined, size: 17),
              label: const Text('Edit'),
            ),
        ],
      ),
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
            onTap: () => _LogNoteSheet.open(context, lead),
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
        Builder(
          builder: (BuildContext context) {
            // Offered from the board's own stage list, so this can never
            // present a stage the CRM would refuse to store.
            final List<Stage> stages =
                context.watch<PipelineBloc>().state.board.stages;
            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final Stage s in stages)
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
            );
          },
        ),
      ],
    );
  }
}

/// Everything on file about this lead, in the sections the server groups it into.
///
/// The rows here used to be a hard-coded list of eight fields, six fewer than
/// the record holds: a rep learned more about a lead from its tile in an Ona
/// answer than from opening the lead itself. Configuration, the budget they
/// can stretch to, must-haves, financing, brokerage — all of it was on the row
/// and none of it reached the page.
///
/// The grouping comes from the API so one place decides which section a field
/// belongs to. A board summary carries no groups, so the fields this page has
/// always known are the fallback.
class _Facts extends StatelessWidget {
  const _Facts({required this.lead});

  final Lead lead;

  List<LeadFieldGroup> get _groups {
    if (lead.fieldGroups.isNotEmpty) return lead.fieldGroups;

    LeadField? f(String key, String label, String value) => value.isEmpty
        ? null
        : LeadField(key: key, label: label, value: value);

    final List<LeadField> fallback = <LeadField?>[
      f('phone', 'Phone', lead.phone),
      f('email', 'Email', lead.email),
      f('budget', 'Budget', lead.budget),
      f('requirement', 'Looking for', lead.requirement),
      f('locality', 'Preferred area', lead.locality),
      f('source', 'Source', lead.source),
      f('owner', 'Owner', lead.owner),
      f('next_follow_up', 'Next follow-up', lead.nextFollowUp),
    ].whereType<LeadField>().toList();

    return <LeadFieldGroup>[
      if (fallback.isNotEmpty)
        LeadFieldGroup(key: 'details', label: 'Details', fields: fallback),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<LeadFieldGroup> groups = _groups;
    if (groups.isEmpty && lead.notes.isEmpty && lead.aiSummary.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (lead.aiSummary.isNotEmpty) ...<Widget>[
          _SummaryCard(text: lead.aiSummary),
          AppSpacing.vGapLg,
        ],
        for (final LeadFieldGroup group in groups) ...<Widget>[
          Text(group.label, style: Theme.of(context).textTheme.labelLarge),
          AppSpacing.vGapSm,
          _FactCard(rows: group.fields),
          AppSpacing.vGapLg,
        ],
        if (lead.tags.isNotEmpty) ...<Widget>[
          ChipRow(
            children: <Widget>[
              for (final String tag in lead.tags)
                TagChip(tag, color: AppColors.inkSoft),
            ],
          ),
          AppSpacing.vGapLg,
        ],
        if (lead.notes.isNotEmpty) ...<Widget>[
          Text('Notes', style: Theme.of(context).textTheme.labelLarge),
          AppSpacing.vGapSm,
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              lead.notes,
              style: TextStyle(
                fontStyle:
                    lead.notesArePrivate ? FontStyle.italic : FontStyle.normal,
                color:
                    lead.notesArePrivate ? AppColors.inkMuted : AppColors.ink,
              ),
            ),
          ),
          AppSpacing.vGapLg,
        ],
      ],
    );
  }
}

/// One section's rows, label on the left and value on the right.
class _FactCard extends StatelessWidget {
  const _FactCard({required this.rows});

  final List<LeadField> rows;

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
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 118,
                  child: Text(
                    rows[i].label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    rows[i].value,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The CRM's own summary of the lead, where one has been generated.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.iris.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.iris.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.iris),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// The other people around the deal, and where each of them stands.
///
/// `lead_contacts` has always been on the lead page in the browser and never
/// on the phone, so a rep could ring the person recorded as the blocker
/// without the app ever mentioning it.
class _People extends StatelessWidget {
  const _People({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    if (lead.people.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'People on this deal',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        AppSpacing.vGapSm,
        for (final LeadPerson person in lead.people)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: person.isBlocker
                      ? AppColors.negative.withValues(alpha: 0.35)
                      : AppColors.cardBorder,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    person.isBlocker
                        ? Icons.block_rounded
                        : (person.isChampion
                            ? Icons.star_rounded
                            : Icons.person_outline_rounded),
                    size: 18,
                    color: person.isBlocker
                        ? AppColors.negative
                        : (person.isChampion
                            ? AppColors.green
                            : AppColors.inkMuted),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          person.name.isNotEmpty ? person.name : 'Unnamed',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (person.subtitle.isNotEmpty)
                          Text(
                            person.subtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (person.notes.isNotEmpty)
                          Text(
                            person.notes,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (person.phone.isNotEmpty)
                    IconButton(
                      tooltip: 'Call ${person.name}',
                      onPressed: () => launchUrl(Uri.parse('tel:${person.phone}')),
                      icon: const Icon(Icons.call_rounded, size: 18),
                    ),
                ],
              ),
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

/// Log an activity: dictate or type, see it, then confirm.
///
/// A sheet rather than a dialog because it carries the composer, and the
/// composer carries the microphone — the whole point of logging from a phone
/// is not typing. Nothing is written until Log is pressed: recognisers mishear
/// names and prices, and a note that silently records the wrong number is
/// worse than no note.
class _LogNoteSheet extends StatelessWidget {
  const _LogNoteSheet({required this.lead});

  final Lead lead;

  static void open(BuildContext context, Lead lead) {
    final PipelineBloc bloc = context.read<PipelineBloc>();
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
        child: _LogNoteSheet(lead: lead),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Log on ${lead.title}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Tap the mic and say what happened, or type it.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          LeadComposer(
            hint: 'e.g. “Site visit done, wants a revised quote.”',
            busy: false,
            onSend: (String note) {
              context
                  .read<PipelineBloc>()
                  .add(PipelineNoteLogged(lead.id, note));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
