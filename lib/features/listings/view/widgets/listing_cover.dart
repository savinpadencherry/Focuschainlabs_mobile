import 'package:flutter/material.dart';

import '../../../../core/get.dart';
import '../../../../core/models/listing.dart';
import '../../../../core/repository/crm_repository.dart';

/// The photo at the top of a property card.
///
/// The link is fetched per card and cached for the app's lifetime, because it
/// is signed and short-lived — it cannot be embedded in the listing payload
/// without either expiring in a cached list or being minted for every property
/// on every search, most of which are never looked at.
///
/// Falls back to the typed gradient when a property has no photo, which is
/// most of them today. A designed placeholder beats a broken image icon, and
/// the gradient is keyed off the listing id so the same property always looks
/// the same.
class ListingCover extends StatefulWidget {
  const ListingCover({
    super.key,
    required this.listing,
    this.height = 150,
    this.borderRadius,
  });

  final Listing listing;
  final double height;
  final BorderRadius? borderRadius;

  /// Signed URLs, kept for the session. Cleared on sign-out with the rest of
  /// the identity state.
  static final Map<String, String> cache = <String, String>{};

  @override
  State<ListingCover> createState() => _ListingCoverState();
}

class _ListingCoverState extends State<ListingCover> {
  String _url = '';
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final String id = widget.listing.id;
    if (ListingCover.cache.containsKey(id)) {
      setState(() {
        _url = ListingCover.cache[id]!;
        _tried = true;
      });
      return;
    }
    // Only ask for properties that claim to have one.
    if (widget.listing.images.isEmpty) {
      setState(() => _tried = true);
      return;
    }
    final String url = await app<CrmRepository>().listingPhoto(id);
    ListingCover.cache[id] = url;
    if (mounted) {
      setState(() {
        _url = url;
        _tried = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = widget.borderRadius ??
        const BorderRadius.vertical(top: Radius.circular(18));

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: _url.isEmpty
            ? _Placeholder(listing: widget.listing, loading: !_tried)
            : Image.network(
                _url,
                fit: BoxFit.cover,
                // A signed link can expire while a list is on screen; the
                // placeholder is the same one an unphotographed property
                // gets, so the card never shows a broken-image glyph.
                errorBuilder: (_, __, ___) =>
                    _Placeholder(listing: widget.listing, loading: false),
                loadingBuilder: (
                  BuildContext context,
                  Widget child,
                  ImageChunkEvent? progress,
                ) {
                  if (progress == null) return child;
                  return _Placeholder(listing: widget.listing, loading: true);
                },
              ),
      ),
    );
  }
}

/// The typed gradient, used when there is no photo.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.listing, required this.loading});

  final Listing listing;
  final bool loading;

  static const List<List<Color>> _palettes = <List<Color>>[
    <Color>[Color(0xFF2A2440), Color(0xFF161026)],
    <Color>[Color(0xFF3A2F52), Color(0xFF1E1832)],
    <Color>[Color(0xFF243A2E), Color(0xFF14201A)],
    <Color>[Color(0xFF32294F), Color(0xFF1A1430)],
  ];

  IconData get _icon {
    final String t = listing.propertyType.toLowerCase();
    if (t.contains('villa')) return Icons.villa_outlined;
    if (t.contains('plot') || t.contains('land')) return Icons.landscape_outlined;
    if (t.contains('office') || t.contains('commercial')) {
      return Icons.storefront_outlined;
    }
    return Icons.apartment_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> colours =
        _palettes[listing.id.hashCode.abs() % _palettes.length];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colours,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white24,
                ),
              )
            : Icon(
                _icon,
                size: 40,
                color: Colors.white.withValues(alpha: 0.28),
              ),
      ),
    );
  }
}
