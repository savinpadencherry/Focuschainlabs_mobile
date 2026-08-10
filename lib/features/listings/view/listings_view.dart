import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/crm_chips.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/shimmer.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/surface_header.dart';
import '../bloc/listings_bloc.dart';
import 'widgets/listing_card.dart';
import 'widgets/listing_deck.dart';
import 'widgets/listing_sheet.dart';
import 'widgets/share_sheet.dart';

/// Inventory search.
class ListingsView extends StatefulWidget {
  const ListingsView({super.key});

  @override
  State<ListingsView> createState() => _ListingsViewState();
}

class _ListingsViewState extends State<ListingsView> {
  /// Swipe is the default: flicking through inventory for a client is one
  /// decision per property. The list stays one tap away for when the job is
  /// "find that specific flat in Hoskote" rather than "show me what we have".
  bool _deck = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<ListingsBloc, ListingsState>(
          listenWhen: (ListingsState a, ListingsState b) =>
              a.shareReceipt != b.shareReceipt && b.shareReceipt > 0,
          listener: (BuildContext context, ListingsState state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.ink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                content: const Row(
                  children: <Widget>[
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.greenBright, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Share recorded on the lead’s timeline.'),
                    ),
                  ],
                ),
              ),
            );
          },
          builder: (BuildContext context, ListingsState state) {
            return Column(
              children: <Widget>[
                SurfaceHeader(
                  title: AppStrings.listingsTitle,
                  subtitle: _subtitle(state),
                  trailing: _ViewToggle(
                    deck: _deck,
                    onChanged: (bool v) => setState(() => _deck = v),
                  ),
                ),
                _Controls(state: state),
                RefreshBar(visible: state.status == ListingsStatus.refreshing),
                Expanded(child: _Body(state: state, deck: _deck)),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _subtitle(ListingsState state) {
    if (state.isLoading) return 'Loading…';
    final int shown = state.results.listings.length;
    if (shown == state.results.total) return '$shown properties';
    return '$shown of ${state.results.total} properties';
  }
}

/// Swipe deck or list. Two modes because the surface answers two different
/// questions: "show me what we have" and "find that specific flat".
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.deck, required this.onChanged});

  final bool deck;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _ToggleIcon(
            icon: Icons.style_rounded,
            selected: deck,
            onTap: () => onChanged(true),
            tooltip: 'Swipe through',
          ),
          _ToggleIcon(
            icon: Icons.view_list_rounded,
            selected: !deck,
            onTap: () => onChanged(false),
            tooltip: 'List',
          ),
        ],
      ),
    );
  }
}

class _ToggleIcon extends StatelessWidget {
  const _ToggleIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Icon(
            icon,
            size: 17,
            color: selected ? AppColors.ink : AppColors.inkMuted,
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatefulWidget {
  const _Controls({required this.state});

  final ListingsState state;

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.state.filters.query);

  @override
  void didUpdateWidget(_Controls old) {
    super.didUpdateWidget(old);
    // Removing a chip changes the query from outside this field.
    if (widget.state.filters.query != _controller.text) {
      _controller.text = widget.state.filters.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ListingsState state = widget.state;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
      child: ContentBounds(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            RoundedSearchField(
              controller: _controller,
              hint: AppStrings.listingsSearchHint,
              onSubmitted: (String q) {
                final ListingsBloc bloc = context.read<ListingsBloc>();
                bloc.add(
                  ListingsFiltered(bloc.state.filters.copyWith(query: q.trim())),
                );
              },
            ),
            if (state.activeChips.isNotEmpty) ...<Widget>[
              AppSpacing.vGapSm,
              // The parsed query, restated as removable chips: a rep verifies
              // what was searched and corrects it in one tap.
              ChipRow(
                children: <Widget>[
                  for (final (String field, String label) in state.activeChips)
                    TagChip(
                      label,
                      color: AppColors.navy,
                      onRemove: () => context
                          .read<ListingsBloc>()
                          .add(ListingsFilterCleared(field)),
                    ),
                ],
              ).animate().fadeIn(duration: 220.ms).slideY(begin: -0.2),
            ],
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.deck});

  final ListingsState state;
  final bool deck;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const SkeletonList(hasBanner: true);

    if (state.status == ListingsStatus.failed && state.results.listings.isEmpty) {
      return ErrorView(
        message: state.error,
        onRetry: () => context.read<ListingsBloc>().add(const ListingsLoaded()),
      );
    }

    final List<Listing> items = state.results.listings;
    if (items.isEmpty) return _NoMatch(state: state);

    if (deck) {
      return ListingDeck(
        listings: items,
        onOpen: (Listing l) => ListingSheet.open(context, l),
        onShare: (Listing l) => ShareSheet.open(context, l),
      );
    }

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: () async =>
          context.read<ListingsBloc>().add(const ListingsLoaded()),
      child: ContentBounds(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          itemCount: items.length,
          separatorBuilder: (_, __) => AppSpacing.vGapMd,
          itemBuilder: (BuildContext context, int i) {
            return ListingCard(
              listing: items[i],
              onTap: () => ListingSheet.open(context, items[i]),
              onShare: () => ShareSheet.open(context, items[i]),
            )
                .animate(delay: (i.clamp(0, 8) * 45).ms)
                .fadeIn(duration: 280.ms)
                .slideY(begin: 0.12, curve: Curves.easeOutCubic);
          },
        ),
      ),
    );
  }
}

/// An empty search names what it searched for and offers to widen it.
///
/// "Nothing to show" tells a rep nothing they can act on. "No 3 BHK in
/// Whitefield under ₹4 Cr" plus one chip per constraint tells them which
/// constraint to drop.
class _NoMatch extends StatelessWidget {
  const _NoMatch({required this.state});

  final ListingsState state;

  @override
  Widget build(BuildContext context) {
    if (state.inventoryIsEmpty) {
      return const EmptyState(
        icon: Icons.apartment_outlined,
        title: AppStrings.listingsEmptyInventory,
        message: 'Properties added on the web app appear here straight away.',
      );
    }

    final String described =
        state.activeChips.map(((String, String) c) => c.$2).join(' · ');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            AppSpacing.vGapLg,
            Text(
              'Nothing matching $described',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            AppSpacing.vGapSm,
            Text(
              'Drop a constraint to widen the search — '
              '${state.results.total} properties in inventory.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            AppSpacing.vGapLg,
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: <Widget>[
                for (final (String field, String label) in state.activeChips)
                  TagChip(
                    'Without $label',
                    color: AppColors.green,
                    filled: false,
                    icon: Icons.close_rounded,
                    onTap: () => context
                        .read<ListingsBloc>()
                        .add(ListingsFilterCleared(field)),
                  ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 340.ms).scale(begin: const Offset(0.96, 0.96));
  }
}
