import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/listing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/crm_chips.dart';
import '../../../pipeline/bloc/pipeline_bloc.dart';
import '../../bloc/listings_bloc.dart';
import 'listing_gallery.dart';
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
            child: CustomScrollView(
              controller: controller,
              slivers: <Widget>[
                // The photos, as a header that collapses into the bar. This
                // sheet is where a rep decides whether to send a property to a
                // client: at the top the pictures should be as large as the
                // screen allows, and once they are reading the specs the
                // pictures should get out of the way without being gone — the
                // title stays pinned so they always know which flat this is.
                if (listing.hasPhotos)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PhotoHeaderDelegate(
                      listing: listing,
                      // A third of the screen, within bounds. Fixed at 300 it
                      // ate a small phone's whole viewport and left no
                      // specifications visible under it.
                      maxExtent: (MediaQuery.sizeOf(context).height * 0.34)
                          .clamp(200.0, 320.0),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(<Widget>[
                // With photos the title rides the header — over the picture
                // when expanded, in the bar when collapsed — so repeating it
                // here would print it twice on the same screen.
                if (!listing.hasPhotos)
                  Text(
                    listing.title,
                    style:
                        text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
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
                    ]),
                  ),
                ),
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

/// The photos as a collapsing header.
///
/// Expanded, the gallery is about a third of the screen — a property is sold
/// on its pictures and this sheet is where a rep decides whether to send it to
/// a client. Scrolling into the specifications shrinks it to a bar rather than
/// scrolling it away: the title stays pinned, so nobody reads a carpet area
/// halfway down and has to scroll back up to check which flat it belongs to.
///
/// A hand-built persistent header rather than `SliverAppBar` +
/// `FlexibleSpaceBar`. The gallery is interactive — you swipe it sideways —
/// and inside a flexible space it would not take the drag: the flexible space
/// lays its background out at full height and offsets it as the bar collapses,
/// and the gesture arena for that subtree is not the simple thing a `PageView`
/// needs. Here the gallery is an ordinary child of an ordinary `Stack` and
/// horizontal drags reach it, which is the whole point of having more than one
/// photograph.
class _PhotoHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _PhotoHeaderDelegate({required this.listing, required this.maxExtent});

  final Listing listing;

  @override
  final double maxExtent;

  /// The collapsed bar: tall enough for the title and nothing more.
  @override
  double get minExtent => kToolbarHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double range = (maxExtent - minExtent).clamp(1.0, double.infinity);
    // 0 fully open, 1 fully collapsed.
    final double t = (shrinkOffset / range).clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // Held at full height and anchored to the top, so collapsing crops the
        // picture from the bottom instead of squashing it.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: maxExtent,
          child: ListingGallery(
            listing: listing,
            height: maxExtent,
            borderRadius: BorderRadius.zero,
            // The title sits on the bottom edge; dots underneath it would be
            // two things competing for the same strip. The counter still says
            // how many photos there are.
            showDots: false,
          ),
        ),
        // Two scrims doing different jobs: the gradient keeps the title legible
        // over a bright photograph, and the flat one fades the picture out as
        // the bar closes so the pinned title never sits on a busy crop.
        // Both ignore pointers — a scrim that swallowed the swipe would undo
        // the reason this is not a FlexibleSpaceBar.
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: <Color>[Color(0x99000000), Color(0x00000000)],
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.55 * t),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 14,
          child: IgnorePointer(
            child: Text(
              listing.title,
              maxLines: t > 0.5 ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                // Shrinks as it docks, the way a large title settles into a bar.
                fontSize: 22 - (5 * t),
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: Colors.white,
                shadows: const <Shadow>[
                  Shadow(color: Color(0xCC161026), blurRadius: 10),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(_PhotoHeaderDelegate old) =>
      old.listing.id != listing.id || old.maxExtent != maxExtent;
}
