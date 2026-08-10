import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/listing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/crm_chips.dart';
import '../../../pipeline/bloc/pipeline_bloc.dart';
import '../../bloc/listings_bloc.dart';
import 'listing_qa.dart';
import 'share_sheet.dart';

/// The full property record, and the two things to do with it: share it, or
/// call the owner.
class ListingSheet extends StatelessWidget {
  const ListingSheet({super.key, required this.listing});

  final Listing listing;

  static Future<void> open(BuildContext context, Listing listing) async {
    final ListingsBloc listings = context.read<ListingsBloc>();
    final PipelineBloc pipeline = context.read<PipelineBloc>();

    // The share button pops this sheet and asks the *caller* to open the
    // composer. Opening it from inside would use a context that has just been
    // removed from the tree, and reading a bloc off a defunct context throws.
    final bool? share = await showModalBottomSheet<bool>(
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
        child: ListingSheet(listing: listing),
      ),
    );

    if (share == true && context.mounted) {
      ShareSheet.open(context, listing);
    } else if (share == false) {
      // Popped by the edit flow. Re-read inventory so the card behind shows
      // the new price rather than the one that was just replaced.
      listings.add(const ListingsLoaded());
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (BuildContext context, ScrollController controller) => Column(
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
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              children: <Widget>[
                Text(
                  listing.title,
                  style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (listing.where.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(listing.where, style: text.bodyMedium),
                ],
                AppSpacing.vGapMd,
                Text(
                  listing.priceFmt,
                  style: text.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.green,
                  ),
                ),
                if (listing.priceNegotiable)
                  Text('Negotiable', style: text.bodySmall),
                AppSpacing.vGapMd,
                ChipRow(
                  children: <Widget>[
                    TagChip(
                      listing.status,
                      color: listing.isAvailable
                          ? AppColors.green
                          : AppColors.inkMuted,
                    ),
                    if (listing.listingIntent.isNotEmpty)
                      TagChip(listing.listingIntent, color: AppColors.navy),
                    if (listing.shareCount > 0)
                      TagChip(
                        'Shared ${listing.shareCount}×',
                        color: AppColors.inkSoft,
                        icon: Icons.send_rounded,
                      ),
                  ],
                ),
                AppSpacing.vGapLg,
                ListingQa(listing: listing),
                AppSpacing.vGapLg,
                _Specs(listing: listing),
                if (listing.description.isNotEmpty) ...<Widget>[
                  AppSpacing.vGapLg,
                  Text('About', style: text.labelLarge),
                  AppSpacing.vGapSm,
                  Text(listing.description, style: text.bodyMedium),
                ],
                if (listing.amenities.isNotEmpty) ...<Widget>[
                  AppSpacing.vGapLg,
                  Text('Amenities', style: text.labelLarge),
                  AppSpacing.vGapSm,
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      for (final String a in listing.amenities)
                        TagChip(a, color: AppColors.inkSoft),
                    ],
                  ),
                ],
                if (listing.ownerName.isNotEmpty ||
                    listing.ownerPhone.isNotEmpty) ...<Widget>[
                  AppSpacing.vGapLg,
                  Text('Owner', style: text.labelLarge),
                  AppSpacing.vGapSm,
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (listing.ownerName.isNotEmpty)
                              Text(
                                listing.ownerName,
                                style:
                                    const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            if (listing.ownerPhone.isNotEmpty)
                              Text(listing.ownerPhone, style: text.bodySmall),
                          ],
                        ),
                      ),
                      if (listing.ownerPhone.isNotEmpty)
                        IconButton.filledTonal(
                          onPressed: () => launchUrl(
                            Uri.parse(
                              'tel:${listing.ownerPhone.replaceAll(RegExp(r'[^0-9+]'), '')}',
                            ),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.call_rounded, size: 19),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final Listing? stored =
                            await ListingEditSheet.open(context, listing);
                        if (stored != null && context.mounted) {
                          // Pop with `false`: the caller reloads inventory
                          // rather than this sheet showing a stale record next
                          // to a price that has just changed.
                          Navigator.pop(context, false);
                        }
                      },
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Share with a lead'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Specs extends StatelessWidget {
  const _Specs({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> specs = <(String, String)>[
      if (listing.bhk.isNotEmpty) ('Configuration', listing.bhk),
      if (listing.propertyType.isNotEmpty) ('Type', listing.propertyType),
      if (listing.builtupAreaSqft > 0)
        ('Built-up', '${listing.builtupAreaSqft} sqft'),
      if (listing.carpetAreaLabel.isNotEmpty)
        ('Carpet', listing.carpetAreaLabel),
      if (listing.bathrooms > 0) ('Bathrooms', '${listing.bathrooms}'),
      if (listing.furnishing.isNotEmpty) ('Furnishing', listing.furnishing),
      if (listing.facing.isNotEmpty) ('Facing', listing.facing),
      if (listing.floorLabel.isNotEmpty) ('Floor', listing.floorLabel),
      if (listing.possessionStatus.isNotEmpty)
        ('Possession', listing.possessionStatus),
      if (listing.ownership.isNotEmpty) ('Ownership', listing.ownership),
      if (listing.reraId.isNotEmpty) ('RERA', listing.reraId),
    ];
    if (specs.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < specs.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 18),
            Row(
              children: <Widget>[
                SizedBox(
                  width: 116,
                  child: Text(
                    specs[i].$1,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: Text(
                    specs[i].$2,
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
