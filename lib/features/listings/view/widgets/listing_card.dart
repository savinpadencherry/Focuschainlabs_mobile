import 'package:flutter/material.dart';

import '../../../../core/models/listing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/crm_chips.dart';

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
          _Banner(listing: listing),
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

/// The coloured header strip.
///
/// The inventory has no hosted image URLs the phone can fetch — `images` holds
/// server-side paths — so rather than render a broken-image box, the card uses
/// a typed gradient and says what the property is. A placeholder that looks
/// deliberate beats one that looks broken.
class _Banner extends StatelessWidget {
  const _Banner({required this.listing});

  final Listing listing;

  List<Color> get _gradient {
    final int seed = listing.id.hashCode.abs();
    const List<List<Color>> palettes = <List<Color>>[
      <Color>[Color(0xFF0B3340), Color(0xFF0A2A29)],
      <Color>[Color(0xFF143C5C), Color(0xFF0B233A)],
      <Color>[Color(0xFF1F4B3F), Color(0xFF0E2A24)],
      <Color>[Color(0xFF3A2F52), Color(0xFF1E1832)],
    ];
    return palettes[seed % palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            listing.propertyType.toLowerCase().contains('villa')
                ? Icons.villa_outlined
                : (listing.propertyType.toLowerCase().contains('plot')
                    ? Icons.landscape_outlined
                    : Icons.apartment_rounded),
            color: Colors.white.withValues(alpha: 0.9),
            size: 26,
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              if (!listing.isAvailable)
                TagChip(
                  listing.status,
                  color: Colors.white,
                  filled: false,
                )
              else if (listing.isUnassigned)
                const TagChip(
                  'Unassigned',
                  color: Colors.white,
                  filled: false,
                  icon: Icons.person_off_outlined,
                ),
              if (listing.shareCount > 0) ...<Widget>[
                const SizedBox(height: 5),
                Text(
                  'Shared ${listing.shareCount}×',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
