import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/models/listing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/crm_chips.dart';
import 'listing_cover.dart';

/// A swipeable deck of properties.
///
/// Right to share, left to pass — the gesture people already know from every
/// other card deck on a phone. It suits inventory better than a list does,
/// because a rep flicking through properties for a client is making one
/// decision per property, and a list asks them to make it while also keeping
/// their place.
///
/// The buttons underneath do the same two things. A gesture nobody is told
/// about is a feature nobody uses, and the buttons are what tell them — as
/// well as being the only way to do this one-handed on a large phone.
class ListingDeck extends StatefulWidget {
  const ListingDeck({
    super.key,
    required this.listings,
    required this.onShare,
    required this.onOpen,
  });

  final List<Listing> listings;
  final ValueChanged<Listing> onShare;
  final ValueChanged<Listing> onOpen;

  @override
  State<ListingDeck> createState() => _ListingDeckState();
}

class _ListingDeckState extends State<ListingDeck> {
  int _index = 0;

  @override
  void didUpdateWidget(ListingDeck old) {
    super.didUpdateWidget(old);
    // A new search is a new deck; keeping the old position would drop the rep
    // into the middle of results they have not seen.
    if (old.listings != widget.listings) _index = 0;
  }

  void _advance() {
    if (_index < widget.listings.length) setState(() => _index++);
  }

  void _restart() => setState(() => _index = 0);

  @override
  Widget build(BuildContext context) {
    if (_index >= widget.listings.length) {
      return _DeckEnd(count: widget.listings.length, onRestart: _restart);
    }

    final Listing top = widget.listings[_index];
    final List<Listing> behind = widget.listings
        .skip(_index + 1)
        .take(2)
        .toList();

    return Column(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Stack(
              alignment: Alignment.topCenter,
              // Expand, so each card gets a tight height. The card's layout
              // uses a Spacer to push the price to the bottom, and a Spacer
              // under loose constraints has no space to take.
              fit: StackFit.expand,
              children: <Widget>[
                // The cards behind, each inset from the top and stopping
                // short of the bottom, so their edges show below the one in
                // front. The first version scaled a single card down behind
                // the top one, which hid it completely — a deck that looks
                // like a single card gives no sense of how much is left.
                for (int i = behind.length - 1; i >= 0; i--)
                  Padding(
                    padding: EdgeInsets.only(
                      top: (i + 1) * 10.0,
                      bottom: _kBottomInset - (i + 1) * 10.0,
                      left: (i + 1) * 8.0,
                      right: (i + 1) * 8.0,
                    ),
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: i == 0 ? 0.85 : 0.6,
                        child: _DeckCard(listing: behind[i], onOpen: (_) {}),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: _kBottomInset),
                  child: Dismissible(
                    key: ValueKey<String>(top.id),
                    direction: DismissDirection.horizontal,
                    onDismissed: (DismissDirection d) {
                      _advance();
                      if (d == DismissDirection.startToEnd) widget.onShare(top);
                    },
                    background: const _SwipeHint(
                      label: 'Share',
                      icon: Icons.send_rounded,
                      color: AppColors.green,
                      alignment: Alignment.centerLeft,
                    ),
                    secondaryBackground: const _SwipeHint(
                      label: 'Pass',
                      icon: Icons.close_rounded,
                      color: AppColors.inkMuted,
                      alignment: Alignment.centerRight,
                    ),
                    child: _DeckCard(listing: top, onOpen: widget.onOpen),
                  ),
                ),
              ],
            ),
          ),
        ),
        _Controls(
          position: _index + 1,
          total: widget.listings.length,
          remaining: widget.listings.length - _index - 1,
          onPass: _advance,
          onShare: () {
            widget.onShare(top);
            _advance();
          },
        ),
      ],
    );
  }
}

/// How much room the stack leaves below the front card for the ones behind.
const double _kBottomInset = 26;

class _DeckCard extends StatelessWidget {
  const _DeckCard({required this.listing, required this.onOpen});

  final Listing listing;
  final ValueChanged<Listing> onOpen;

  List<Color> get _gradient {
    const List<List<Color>> palettes = <List<Color>>[
      <Color>[Color(0xFF0B3340), Color(0xFF0A2A29)],
      <Color>[Color(0xFF143C5C), Color(0xFF0B233A)],
      <Color>[Color(0xFF1F4B3F), Color(0xFF0E2A24)],
      <Color>[Color(0xFF3A2F52), Color(0xFF1E1832)],
    ];
    return palettes[listing.id.hashCode.abs() % palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => onOpen(listing),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 16),
              spreadRadius: -10,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ListingCover(
              listing: listing,
              height: 190,
              // Top corners only — the container clips the bottom ones.
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusXl),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              child: Row(
                children: <Widget>[
                  if (listing.shareCount > 0)
                    Text(
                      'Shared ${listing.shareCount}×',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
            Text(
              listing.priceFmt,
              style: text.displaySmall?.copyWith(
                color: AppColors.greenBright,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              listing.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            if (listing.where.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.place_outlined,
                    size: 15,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      listing.where,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final String f in listing.facts)
                  TagChip(f, color: Colors.white, filled: false),
                if (!listing.isAvailable)
                  TagChip(listing.status, color: AppColors.atRisk),
                if (listing.isUnassigned)
                  const TagChip(
                    'Unassigned',
                    color: Colors.white,
                    filled: false,
                    icon: Icons.person_off_outlined,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.touch_app_outlined,
                  size: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 5),
                Text(
                  'Tap for full details',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What shows behind the card as it is dragged.
class _SwipeHint extends StatelessWidget {
  const _SwipeHint({
    required this.label,
    required this.icon,
    required this.color,
    required this.alignment,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 34),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.position,
    required this.total,
    required this.remaining,
    required this.onPass,
    required this.onShare,
  });

  final int position;
  final int total;
  final int remaining;
  final VoidCallback onPass;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _RoundButton(
                icon: Icons.close_rounded,
                color: AppColors.inkMuted,
                onTap: onPass,
                tooltip: 'Pass',
              ),
              const SizedBox(width: 26),
              _RoundButton(
                icon: Icons.send_rounded,
                color: AppColors.green,
                onTap: onShare,
                large: true,
                tooltip: 'Share',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            remaining > 0
                ? '$position of $total · $remaining more'
                : '$position of $total · last one',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
    this.large = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final double size = large ? 62 : 52;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: large ? color : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: large ? color : AppColors.cardBorderStrong,
              width: 1.5,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: (large ? color : AppColors.navy)
                    .withValues(alpha: large ? 0.36 : 0.12),
                blurRadius: large ? 18 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: large ? Colors.white : color,
            size: large ? 27 : 22,
          ),
        ),
      ),
    );
  }
}

class _DeckEnd extends StatelessWidget {
  const _DeckEnd({required this.count, required this.onRestart});

  final int count;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.done_all_rounded,
                size: 38,
                color: AppColors.green,
              ),
            ),
            AppSpacing.vGapLg,
            Text(
              'That is all $count',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            AppSpacing.vGapSm,
            Text(
              'You have been through every property matching this search.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            AppSpacing.vGapLg,
            FilledButton.tonalIcon(
              onPressed: onRestart,
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: const Text('Go through them again'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 340.ms).scale(begin: const Offset(0.96, 0.96));
  }
}
