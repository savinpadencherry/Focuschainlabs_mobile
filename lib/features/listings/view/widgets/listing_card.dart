import 'package:flutter/material.dart';

import '../../../../core/models/listing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/crm_chips.dart';
import 'listing_cover.dart';

/// One property.
///
/// Price is the largest thing on the card because it is the first question
/// every client asks, and the share count is on the face because "have we
/// already sent this to them" is the second.
class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.onShare,
  });

  final Listing listing;
  final VoidCallback onTap;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: <Widget>[
              ListingCover(listing: listing),
              // The badges sit on the photo, so a scrim keeps them legible
              // whatever the picture underneath happens to be.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.black.withValues(alpha: 0.34),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.10),
                      ],
                      stops: const <double>[0, 0.55, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: _BannerBadges(listing: listing),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                if (listing.where.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 3),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: AppColors.inkMuted,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          listing.where,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        listing.priceFmt,
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.green,
                          height: 1,
                        ),
                      ),
                    ),
                    if (onShare != null)
                      FilledButton.tonalIcon(
                        onPressed: onShare,
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 15),
                        label: const Text('Share'),
                      ),
                  ],
                ),
                if (listing.facts.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  ChipRow(
                    children: <Widget>[
                      for (final String f in listing.facts)
                        TagChip(f, color: AppColors.inkSoft),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The badges that sit over the cover photo.
class _BannerBadges extends StatelessWidget {
  const _BannerBadges({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!listing.isAvailable)
          TagChip(listing.status, color: Colors.white, filled: false)
        else if (listing.isUnassigned)
          const TagChip(
            'Unassigned',
            color: Colors.white,
            filled: false,
            icon: Icons.person_off_outlined,
          ),
        const Spacer(),
        // How many pictures there are to see, because the card shows one and
        // the swipe gesture that would reveal the rest lives in the sheet.
        if (listing.photoCount > 1) ...<Widget>[
          _Pill(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.photo_library_outlined,
                    size: 11, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  '${listing.photoCount}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],
        if (listing.shareCount > 0)
          _Pill(
            child: Text(
              'Shared ${listing.shareCount}\u00d7',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

/// A dark lozenge, legible over any photograph.
class _Pill extends StatelessWidget {
  const _Pill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
      ),
      child: child,
    );
  }
}
