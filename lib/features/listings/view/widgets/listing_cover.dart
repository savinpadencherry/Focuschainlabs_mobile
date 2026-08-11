import 'package:flutter/material.dart';

import '../../../../core/get.dart';
import '../../../../core/models/listing.dart';
import '../../../../core/services/api/secona_api.dart';

/// The photo at the top of a property card.
///
/// The bytes come from the API itself rather than from a signed storage link.
/// Signing needs a key or the IAM signBlob permission, and Cloud Run's
/// metadata credentials have neither — the first version minted links that
/// were never valid, which is why these cards were dark boxes. The web app
/// reads the bytes too, for the same reason.
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

  @override
  State<ListingCover> createState() => _ListingCoverState();
}

class _ListingCoverState extends State<ListingCover> {
  Map<String, String>? _headers;
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    // Only fetch for properties that claim to have a photo; the rest get the
    // placeholder without a round trip.
    if (widget.listing.images.isEmpty) {
      setState(() => _tried = true);
      return;
    }
    try {
      final Map<String, String> headers = await app<SeconaApi>().authHeaders();
      if (mounted) {
        setState(() {
          _headers = headers;
          _tried = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _tried = true);
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
        child: _headers == null
            ? _Placeholder(listing: widget.listing, loading: !_tried)
            : Image.network(
                app<SeconaApi>()
                    .urlFor('/api/listings/${widget.listing.id}/photo'),
                headers: _headers,
                fit: BoxFit.cover,
                // A property whose photo has been removed 404s; the
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
