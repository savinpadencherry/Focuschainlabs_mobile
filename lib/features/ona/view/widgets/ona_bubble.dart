import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/listing.dart';
import '../../../../core/models/ona.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/crm_chips.dart';
import '../../../listings/view/widgets/listing_card.dart';
import '../../../listings/view/widgets/listing_sheet.dart';
import '../../../listings/view/widgets/share_sheet.dart';
import '../../../pipeline/view/widgets/lead_sheet.dart';
import '../../bloc/ona_bloc.dart';
import 'ona_mark.dart';
import 'ona_receipt.dart';

/// One turn in the thread.
class OnaBubble extends StatelessWidget {
  const OnaBubble({super.key, required this.turn});

  final OnaTurn turn;

  @override
  Widget build(BuildContext context) {
    if (turn.isUser) return _UserBubble(text: turn.text);
    return _OnaBubble(turn: turn);
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 44, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, height: 1.35),
        ),
      ),
    );
  }
}

class _OnaBubble extends StatelessWidget {
  const _OnaBubble({required this.turn});

  final OnaTurn turn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: OnaMark(size: 26),
          ),
          const SizedBox(width: 10),
          Expanded(child: _Content(turn: turn)),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.turn});

  final OnaTurn turn;

  @override
  Widget build(BuildContext context) {
    if (turn.pending) return const OnaThinking();

    if (turn.hasError) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.negative.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.negative.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.cloud_off_rounded,
                size: 17, color: AppColors.negative),
            const SizedBox(width: 8),
            Expanded(
              child: Text(turn.error, style: const TextStyle(height: 1.35)),
            ),
          ],
        ),
      );
    }

    final OnaReply? reply = turn.reply;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // What Ona took the message to mean, in checkable terms. Never a
        // confidence score — a model reports 100% when it is wrong too.
        if (reply != null && reply.understood.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: TagChip(
              reply.understood.first,
              color: AppColors.inkMuted,
              icon: Icons.check_rounded,
            ),
          ),
        if (turn.text.isNotEmpty)
          Text(turn.text, style: const TextStyle(height: 1.4, fontSize: 15)),
        if (turn.receipt != null) ...<Widget>[
          const SizedBox(height: 10),
          OnaReceipt(lead: turn.receipt!),
        ],
        for (final OnaAnswer answer in turn.answers)
          _AnswerBody(answer: answer),
        if (reply?.clarify != null) _ClarifyOptions(clarify: reply!.clarify!),
        if (reply?.needsConfirmation == true) _ConfirmStrip(reply: reply!),
      ],
    );
  }
}

/// The per-intent body of an answer.
class _AnswerBody extends StatelessWidget {
  const _AnswerBody({required this.answer});

  final OnaAnswer answer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (answer.isBriefing) _Briefing(answer: answer),
        if (answer.deals.isNotEmpty) _Deals(deals: answer.deals),
        if (answer.listings.isNotEmpty) _Listings(listings: answer.listings),
        if (answer.handoff != null) _Handoff(handoff: answer.handoff!),
        // Anything Ona asks must be tappable, or the rep types "sure" and is
        // told they were not understood.
        if (answer.offers.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final OnaOffer o in answer.offers)
                TagChip(
                  o.label,
                  color: AppColors.green,
                  filled: false,
                  icon: Icons.bolt_rounded,
                  onTap: () => context
                      .read<OnaBloc>()
                      .add(OnaAsked(o.prompt, fromChip: true)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Briefing extends StatelessWidget {
  const _Briefing({required this.answer});

  final OnaAnswer answer;

  @override
  Widget build(BuildContext context) {
    final int due = (answer.tasks['due_now'] as List<dynamic>? ?? <dynamic>[]).length;
    final int risky = (answer.risk['deals'] as List<dynamic>? ?? <dynamic>[]).length;
    final List<dynamic> showings =
        answer.morning['showings'] as List<dynamic>? ?? <dynamic>[];

    if (due == 0 && risky == 0 && showings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: <Widget>[
          if (showings.isNotEmpty)
            _Tile(
              label: 'Showings',
              value: '${showings.length}',
              color: AppColors.navy,
              icon: Icons.event_available_rounded,
            ),
          if (due > 0) ...<Widget>[
            if (showings.isNotEmpty) const SizedBox(width: 8),
            _Tile(
              label: 'Due now',
              value: '$due',
              color: AppColors.atRisk,
              icon: Icons.schedule_rounded,
            ),
          ],
          if (risky > 0) ...<Widget>[
            const SizedBox(width: 8),
            _Tile(
              label: 'At risk',
              value: '$risky',
              color: AppColors.negative,
              icon: Icons.trending_down_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 19,
                height: 1,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Deals come back from focus/risk/pipeline answers. Each is a lead, so each
/// opens the lead sheet — the same place the pipeline tab lands.
class _Deals extends StatelessWidget {
  const _Deals({required this.deals});

  final List<Map<String, dynamic>> deals;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: <Widget>[
          for (final Map<String, dynamic> d in deals.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: InkWell(
                onTap: () {
                  final String id = (d['contact_id'] ?? '').toString();
                  if (id.isNotEmpty) LeadSheet.open(context, id);
                },
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              (d['company'] ?? d['contact_name'] ?? 'Lead')
                                  .toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            if ((d['stage'] ?? '').toString().isNotEmpty)
                              Text(
                                (d['stage'] ?? '').toString(),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      if ((d['value_fmt'] ?? '').toString().isNotEmpty)
                        Text(
                          (d['value_fmt']).toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.green,
                          ),
                        ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.inkMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Properties render as cards with a Share button that opens the composer in
/// place — never a link that leaves the conversation.
class _Listings extends StatelessWidget {
  const _Listings({required this.listings});

  final List<Listing> listings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: <Widget>[
          for (final Listing l in listings.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ListingCard(
                listing: l,
                onTap: () => ListingSheet.open(context, l),
                onShare: () => ShareSheet.open(context, l),
              ),
            ),
        ],
      ),
    );
  }
}

/// A proposed write, with the button that performs it.
class _Handoff extends StatelessWidget {
  const _Handoff({required this.handoff});

  final OnaHandoff handoff;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                handoff.writes
                    ? 'Nothing is saved until you confirm.'
                    : 'Ready when you are.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            FilledButton(
              onPressed: () => _open(context),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: Text(handoff.actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    if (handoff.kind == 'lead' && handoff.contactId.isNotEmpty) {
      LeadSheet.open(context, handoff.contactId);
      return;
    }
    // Everything else needs a composer that does not exist on this surface
    // yet; the pipeline tab is where those writes are made, so send the rep
    // there rather than silently doing nothing.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          handoff.contactName.isEmpty
              ? 'Open the lead in Pipeline to do that.'
              : 'Open ${handoff.contactName} in Pipeline to do that.',
        ),
      ),
    );
  }
}

class _ClarifyOptions extends StatelessWidget {
  const _ClarifyOptions({required this.clarify});

  final OnaClarify clarify;

  @override
  Widget build(BuildContext context) {
    if (clarify.options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: <Widget>[
          for (final String option in clarify.options)
            TagChip(
              option,
              color: AppColors.navy,
              filled: false,
              onTap: () =>
                  context.read<OnaBloc>().add(OnaAsked(option, fromChip: true)),
            ),
        ],
      ),
    );
  }
}

/// Anything with more than one step, or a step that leaves the app, is shown
/// back before it runs.
class _ConfirmStrip extends StatelessWidget {
  const _ConfirmStrip({required this.reply});

  final OnaReply reply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.cardBorderStrong),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final String line in reply.summary)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.arrow_right_rounded,
                        size: 18, color: AppColors.green),
                    Expanded(child: Text(line)),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                TextButton(
                  onPressed: () =>
                      context.read<OnaBloc>().add(const OnaDeclined()),
                  child: const Text('No, cancel'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () =>
                      context.read<OnaBloc>().add(const OnaConfirmed()),
                  child: const Text('Yes, go ahead'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
