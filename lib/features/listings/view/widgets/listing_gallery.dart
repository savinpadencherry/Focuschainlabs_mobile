import 'package:flutter/material.dart';

import '../../../../core/models/listing.dart';
import '../../../../core/theme/app_colors.dart';
import 'listing_cover.dart';

/// Every photo on a property, swipeable.
///
/// The app could only ever reach the first one: `/photo` served the cover and
/// nothing addressed the rest, so a property with eleven pictures on the web
/// app was one picture on the phone. A property is sold on its photos, and a
/// rep standing in front of a client had the worst version of the listing.
///
/// Bytes come from the API rather than a signed link — see [ListingCover] for
/// why signing does not work here. Each page is its own request, made when the
/// page is built, so opening a property costs one photo and not eleven.
class ListingGallery extends StatefulWidget {
  const ListingGallery({
    super.key,
    required this.listing,
    this.height = 232,
    this.borderRadius,
  });

  final Listing listing;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<ListingGallery> createState() => _ListingGalleryState();
}

class _ListingGalleryState extends State<ListingGallery> {
  final PageController _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int count = widget.listing.photoCount;
    final BorderRadius radius =
        widget.borderRadius ?? BorderRadius.circular(18);

    // One photo, or none, is not a gallery — the dots and the counter would
    // be furniture around a single picture.
    if (count <= 1) {
      return ListingCover(
        listing: widget.listing,
        height: widget.height,
        borderRadius: radius,
      );
    }

    return Stack(
      children: <Widget>[
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pages,
            itemCount: count,
            onPageChanged: (int i) => setState(() => _index = i),
            itemBuilder: (BuildContext context, int i) => ListingCover(
              listing: widget.listing,
              index: i,
              height: widget.height,
              borderRadius: radius,
            ),
          ),
        ),
        Positioned(
          right: 10,
          top: 10,
          child: _Counter(current: _index + 1, total: count),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 10,
          child: _Dots(count: count, current: _index),
        ),
      ],
    );
  }
}

/// "3 / 11". The dots say where you are; this says how much is left.
class _Counter extends StatelessWidget {
  const _Counter({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$current / $total',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    // Past about eight the dots stop being countable and start being a smear;
    // the counter in the corner is the readable answer at that point.
    if (count > 8) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == current ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == current
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(999),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.25),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
