import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/get.dart';
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

/// Root authenticated surface: Ona · Pipeline · Listings.
///
/// Listings shows for every tenant. Strictly it is a real-estate concept and
/// `focuschainlabs` is registered `b2b_saas`, so gating it by vertical was the
/// tidier rule — but FCL has inventory on file and works property deals, and
/// hiding the only way to reach records that exist is worse than showing a tab
/// whose label does not match a config field. The vertical is still carried on
/// [Me] for whenever that config catches up with how the workspace is used.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;
  bool _resolving = true;

  /// The data blocs, held so a lifecycle callback can refresh them without a
  /// BuildContext. Ona is deliberately absent: it holds a conversation, and
  /// re-running the brief on resume would throw one away.
  PipelineBloc? _pipeline;
  ListingsBloc? _listings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resolve();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-read on resume.
  ///
  /// The web app is the other half of this system and colleagues are working
  /// in it all day. Coming back to a phone that is showing what the pipeline
  /// looked like before lunch — and only correcting itself if you happen to
  /// pull down — is the kind of staleness that gets acted on.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _pipeline?.add(const PipelineLoaded());
    _listings?.add(const ListingsLoaded());
  }

  /// Switching to a tab re-reads it, for the same reason.
  void _refreshFor(int index) {
    switch (index) {
      case 1:
        _pipeline?.add(const PipelineLoaded());
      case 2:
        _listings?.add(const ListingsLoaded());
    }
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
      // greeting and the avatar just fall back to neutral text.
    }
    if (mounted) setState(() => _resolving = false);
  }

  void _select(int value) {
    if (value == _index) return;
    setState(() => _index = value);
    _refreshFor(value);
  }

  @override
  Widget build(BuildContext context) {
    if (_resolving) {
      return const Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(child: CircularProgressIndicator(color: AppColors.green)),
      );
    }

    final CrmRepository repository = app<CrmRepository>();

    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        // Each create assigns the field as well as returning the bloc, so the
        // lifecycle callback always holds the live instance. Caching with `??=`
        // would hand back a closed bloc if a provider were ever recreated.
        BlocProvider<OnaBloc>(
          create: (_) =>
              OnaBloc(repository: repository)..add(const OnaOpened()),
        ),
        BlocProvider<PipelineBloc>(
          create: (_) {
            final PipelineBloc bloc = PipelineBloc(repository: repository);
            _pipeline = bloc;
            return bloc..add(const PipelineLoaded());
          },
        ),
        BlocProvider<ListingsBloc>(
          create: (_) {
            final ListingsBloc bloc = ListingsBloc(repository: repository);
            _listings = bloc;
            return bloc..add(const ListingsLoaded());
          },
        ),
      ],
      child: _ShellScaffold(index: _index, onSelect: _select),
    );
  }
}

class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  List<NavItem> get _items => navDestinations;

  /// `num.clamp` returns num, and an index has to be an int.
  int get _safeIndex {
    final int last = _items.length - 1;
    return index < 0 ? 0 : (index > last ? last : index);
  }

  Widget get _body {
    const List<Widget> pages = <Widget>[
      OnaView(),
      PipelineView(),
      ListingsView(),
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
            AppConstants.appName,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ],
    );
  }
}
