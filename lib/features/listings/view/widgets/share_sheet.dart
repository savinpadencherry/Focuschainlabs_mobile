import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/listing.dart';
import '../../../../core/models/pipeline.dart';
import '../../../../core/services/api/identity_cache.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/phone_number.dart';
import '../../../../shared/widgets/crm_chips.dart';
import '../../../pipeline/bloc/pipeline_bloc.dart';
import '../../bloc/listings_bloc.dart';

/// Send a property to a lead on WhatsApp.
///
/// Pick a lead, read the message that will go out, then send. The composer
/// opens in place rather than linking away, and nothing is recorded until the
/// rep has both chosen a recipient and pressed send — a share that reaches a
/// client is the last place for a surprise.
///
/// Leads without a messageable number are listed but disabled, with the reason
/// shown. Filtering them out would leave a rep hunting for a client who is in
/// the CRM and simply has a landline on file; naming the reason turns that into
/// something they can go and fix.
class ShareSheet extends StatelessWidget {
  const ShareSheet({super.key, required this.listing});

  final Listing listing;

  static void open(BuildContext context, Listing listing) {
    final ListingsBloc listings = context.read<ListingsBloc>();
    final PipelineBloc pipeline = context.read<PipelineBloc>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<ListingsBloc>.value(value: listings),
          BlocProvider<PipelineBloc>.value(value: pipeline),
        ],
        child: ShareSheet(listing: listing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (BuildContext context, ScrollController controller) =>
          _Body(listing: listing, controller: controller),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.listing, required this.controller});

  final Listing listing;
  final ScrollController controller;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  Lead? _lead;
  String _search = '';
  bool _sending = false;

  /// Which country a bare local number belongs to is the workspace's business,
  /// not this widget's. Falls back to India, which is where every tenant is
  /// today and what the server defaults to.
  String get _dialCode => IdentityCache.current?.dialCode ?? '91';

  PhoneNumber _number(Lead lead) =>
      PhoneNumber.parse(lead.phone, dialCode: _dialCode);

  /// What the client receives. Assembled from the record, so a rep can read it
  /// before it goes rather than trusting a template they cannot see.
  String get _message {
    final Listing l = widget.listing;
    final StringBuffer b = StringBuffer()..writeln(l.title);
    if (l.priceFmt.isNotEmpty) b.writeln(l.priceFmt);
    if (l.where.isNotEmpty) b.writeln(l.where);
    if (l.facts.isNotEmpty) b.writeln(l.facts.join(' · '));
    if (l.description.isNotEmpty) {
      b
        ..writeln()
        ..writeln(l.description);
    }
    return b.toString().trim();
  }

  Future<void> _send() async {
    final Lead? lead = _lead;
    if (lead == null || _sending) return;
    final PhoneNumber number = _number(lead);
    if (!number.canWhatsApp) return;

    setState(() => _sending = true);

    // Recorded before the handoff. Once WhatsApp is in front of the rep this
    // app is in the background and cannot observe what happened there, so the
    // honest thing is to record that the property was sent to this lead and
    // let the timeline show it — not to claim delivery we cannot see.
    context.read<ListingsBloc>().add(
          ListingsShared(
            listingIds: <String>[widget.listing.id],
            contactId: lead.id,
            channel: 'whatsapp',
          ),
        );

    final Uri uri = number.whatsAppUri(_message);
    bool opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }

    if (!mounted) return;
    if (opened) {
      Navigator.pop(context);
      return;
    }
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open WhatsApp on this phone.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    final List<Lead> leads = context
        .watch<PipelineBloc>()
        .state
        .board
        .leads
        .where((Lead l) =>
            _search.isEmpty ||
            l.title.toLowerCase().contains(_search.toLowerCase()))
        .toList()
      // Messageable leads first: the rep is here to send something, and a
      // list that opens on the ones they cannot send to buries the job.
      ..sort((Lead a, Lead b) {
        final bool aOk = _number(a).canWhatsApp;
        final bool bOk = _number(b).canWhatsApp;
        if (aOk == bOk) return 0;
        return aOk ? -1 : 1;
      });

    final PhoneNumber? chosen = _lead == null ? null : _number(_lead!);

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
        Expanded(
          child: ListView(
            controller: widget.controller,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            children: <Widget>[
              Text(
                'Send this property',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(widget.listing.title, style: text.bodyMedium),
              AppSpacing.vGapLg,
              Text('Send to', style: text.labelLarge),
              AppSpacing.vGapSm,
              TextField(
                onChanged: (String v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search your leads…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
              AppSpacing.vGapSm,
              if (leads.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    _search.isEmpty
                        ? 'No leads in your pipeline yet.'
                        : 'No lead matches “$_search”.',
                    style: text.bodyMedium,
                  ),
                )
              else
                for (final Lead l in leads.take(25))
                  _LeadRow(
                    lead: l,
                    number: _number(l),
                    selected: _lead?.id == l.id,
                    onTap: () => setState(() => _lead = l),
                  ),
              AppSpacing.vGapLg,
              Text('They will receive', style: text.labelLarge),
              AppSpacing.vGapSm,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(_message, style: text.bodyMedium),
              ),
              AppSpacing.vGapSm,
              Text(
                'WhatsApp opens with this ready to send. Nothing leaves the '
                'app until you press send there.',
                style: text.bodySmall,
              ),
            ],
          ),
        ),
        _SendBar(
          lead: _lead,
          number: chosen,
          sending: _sending,
          onSend: _send,
        ),
      ],
    );
  }
}

/// One lead in the picker: name, stage, and whether it can be messaged.
class _LeadRow extends StatelessWidget {
  const _LeadRow({
    required this.lead,
    required this.number,
    required this.selected,
    required this.onTap,
  });

  final Lead lead;
  final PhoneNumber number;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool can = number.canWhatsApp;
    return Opacity(
      opacity: can ? 1 : 0.55,
      child: InkWell(
        onTap: can ? onTap : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.green.withValues(alpha: 0.08) : null,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: selected
                    ? AppColors.green
                    : (can ? AppColors.inkMuted : AppColors.cardBorderStrong),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      lead.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Row(
                      children: <Widget>[
                        if (can)
                          const Icon(
                            Icons.chat_rounded,
                            size: 11,
                            color: Color(0xFF25D366),
                          )
                        else
                          const Icon(
                            Icons.phone_disabled_rounded,
                            size: 11,
                            color: AppColors.inkMuted,
                          ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            can ? number.pretty : number.reason,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StageChip(lead.stage),
            ],
          ),
        ),
      ),
    );
  }
}

/// The send button, and why it is disabled when it is.
class _SendBar extends StatelessWidget {
  const _SendBar({
    required this.lead,
    required this.number,
    required this.sending,
    required this.onSend,
  });

  final Lead? lead;
  final PhoneNumber? number;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final bool ready = lead != null && (number?.canWhatsApp ?? false);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (lead != null && !(number?.canWhatsApp ?? false)) ...<Widget>[
              Text(
                '${lead!.title} has no number we can message. '
                'Add a mobile number on the lead first.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.atRisk),
              ),
              AppSpacing.vGapSm,
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: ready && !sending ? onSend : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  disabledBackgroundColor: AppColors.paper3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
                icon: sending
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.chat_rounded, size: 19),
                label: Text(
                  lead == null
                      ? 'Pick a lead first'
                      : (ready
                          ? 'Send to ${lead!.title} on WhatsApp'
                          : 'No WhatsApp number'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
