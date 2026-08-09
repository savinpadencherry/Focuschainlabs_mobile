import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/listing.dart';
import '../../../../core/models/pipeline.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/crm_chips.dart';
import '../../../pipeline/bloc/pipeline_bloc.dart';
import '../../bloc/listings_bloc.dart';

/// Pick a lead, review the message, then send.
///
/// The composer opens *in place* rather than linking away, and nothing is
/// recorded until the user has both chosen a recipient and pressed send. The
/// message is shown in full first — a share that reaches a client is the last
/// place for a surprise.
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
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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

  /// What the client will actually receive.
  String get _message {
    final Listing l = widget.listing;
    final StringBuffer b = StringBuffer()
      ..writeln(l.title)
      ..writeln(l.priceFmt);
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
    if (lead == null) return;

    // Recorded first. If the handoff to WhatsApp fails or the rep backs out of
    // it, a share row that says "sent" would be a lie — but recording after a
    // successful launch is impossible to observe, because the app is
    // backgrounded by then. Recording first and letting the rep see the row is
    // the honest half of an unavoidable trade.
    context.read<ListingsBloc>().add(ListingsShared(
          listingIds: <String>[widget.listing.id],
          contactId: lead.id,
          channel: 'whatsapp',
        ));

    final String phone = lead.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final Uri uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(_message)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (mounted) Navigator.pop(context);
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
            l.phone.isNotEmpty &&
            (_search.isEmpty ||
                l.title.toLowerCase().contains(_search.toLowerCase())))
        .toList();

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
                'Share this property',
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
                  ),
                ),
              ),
              AppSpacing.vGapSm,
              if (leads.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'No leads with a phone number to share to.',
                    style: text.bodyMedium,
                  ),
                )
              else
                // A plain tappable row rather than RadioListTile: the radio
                // group API is deprecated on current Flutter stable, and the
                // whole row being the target is a bigger touch area anyway.
                ...leads.take(20).map(
                      (Lead l) => ListTile(
                        onTap: () => setState(() => _lead = l),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          _lead?.id == l.id
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: _lead?.id == l.id
                              ? AppColors.green
                              : AppColors.inkMuted,
                          size: 20,
                        ),
                        title: Text(l.title),
                        subtitle: Text(l.phone),
                        trailing: StageChip(l.stage),
                      ),
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
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _lead == null ? null : _send,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _lead == null
                      ? 'Pick a lead first'
                      : 'Send to ${_lead!.title} on WhatsApp',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
