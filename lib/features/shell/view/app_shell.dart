import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/get.dart';
import '../../../core/models/listing.dart';
import '../../../core/repository/crm_repository.dart';
import '../../../core/services/api/identity_cache.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../listings/bloc/listings_bloc.dart';
import '../../listings/view/listings_view.dart';
import '../../ona/bloc/ona_bloc.dart';
import '../../ona/view/ona_view.dart';
import '../../pipeline/bloc/pipeline_bloc.dart';
import '../../pipeline/view/pipeline_view.dart';
import 'nav_destinations.dart';
import 'widgets/pill_nav_bar.dart';

/// Root authenticated surface.
///
/// The tab set depends on the tenant. Property inventory is a real-estate
/// concept, so a B2B SaaS workspace has no Listings surface — showing one is
/// showing a tool for somebody else's business. The shell therefore resolves
/// who the user is before it can draw its own navigation, which is why this
/// loads identity rather than reading it lazily like the headers do.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _resolving = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    if (IdentityCache.current != null) {
      setState(() => _resolving = false);
      return;
    }
    try {
      IdentityCache.current = await app<CrmRepository>().me();
    } catch (_) {
      // Unreachable or not a member. The surfaces report it properly; the
      // shell just falls back to the tab set that is always valid.
    }
    if (mounted) setState(() => _resolving = false);
  }

  void _select(int value) {
    if (value != _index) setState(() => _index = value);
  }

  @override
  Widget build(BuildContext context) {
    if (_resolving) {
      return const Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(child: CircularProgressIndicator(color: AppColors.green)),
      );
    }

    final Me? me = IdentityCache.current;
    final bool showListings = me?.isRealEstate ?? false;
    final CrmRepository repository = app<CrmRepository>();

    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<OnaBloc>(
          create: (_) => OnaBloc(repository: repository)..add(const OnaOpened()),
        ),
        BlocProvider<PipelineBloc>(
          create: (_) =>
              PipelineBloc(repository: repository)..add(const PipelineLoaded()),
        ),
        // Provided even when the tab is hidden: Ona answers property questions
        // for any tenant that has inventory on file, and its listing cards
        // need this bloc to open a share composer.
        BlocProvider<ListingsBloc>(
          create: (_) => ListingsBloc(repository: repository)
            ..add(showListings ? const ListingsLoaded() : const ListingsIdle()),
        ),
      ],
      child: _ShellScaffold(
        index: _index,
        onSelect: _select,
        showListings: showListings,
      ),
    );
  }
}

class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({
    required this.index,
    required this.onSelect,
    required this.showListings,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final bool showListings;

  List<NavItem> get _items => navDestinationsFor(showListings: showListings);

  /// `num.clamp` returns num, and an index has to be an int.
  int get _safeIndex {
    final int last = _items.length - 1;
    return index < 0 ? 0 : (index > last ? last : index);
  }

  Widget get _body {
    final List<Widget> pages = <Widget>[
      const OnaView(),
      const PipelineView(),
      if (showListings) const ListingsView(),
    ];
    return IndexedStack(
      index: _safeIndex,
      children: <Widget>[
        for (int i = 0; i < pages.length; i++)
          _PageFade(visible: i == index, child: pages[i]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: (_) => Scaffold(
        backgroundColor: AppColors.paper,
        // Deliberately NOT extendBody. The nav bar floats visually, but the
        // body must end above it — with extendBody the composer and the last
        // list row were drawn underneath it and could not be tapped.
        body: _body,
        bottomNavigationBar: PillNavBar(
          index: _safeIndex,
          onSelect: onSelect,
          items: _items,
        ),
      ),
      tablet: (_) =>
          _WideShell(index: _safeIndex, onSelect: onSelect, body: _body, items: _items),
      desktop: (_) => _WideShell(
        index: _safeIndex,
        onSelect: onSelect,
        body: _body,
        items: _items,
        extended: true,
      ),
    );
  }
}

/// Fades and lifts a page as it becomes the visible one.
class _PageFade extends StatelessWidget {
  const _PageFade({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      opacity: visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0, 0.015),
        child: child,
      ),
    );
  }
}

class _WideShell extends StatelessWidget {
  const _WideShell({
    required this.index,
    required this.onSelect,
    required this.body,
    required this.items,
    this.extended = false,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final Widget body;
  final List<NavItem> items;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Row(
        children: <Widget>[
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height,
              ),
              child: IntrinsicHeight(
                child: NavigationRail(
                  extended: extended,
                  minWidth: 76,
                  minExtendedWidth: 208,
                  backgroundColor: AppColors.paper,
                  selectedIndex: index,
                  onDestinationSelected: onSelect,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: _RailLeading(extended: extended),
                  ),
                  destinations: items
                      .map((NavItem n) => NavigationRailDestination(
                            icon: Icon(n.icon),
                            selectedIcon: Icon(n.selectedIcon),
                            label: Text(n.label),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _RailLeading extends StatelessWidget {
  const _RailLeading({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.logoGradient),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Text(
            'O',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        if (extended) ...<Widget>[
          const SizedBox(width: 10),
          const Text(
            'Secona',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ],
    );
  }
}
