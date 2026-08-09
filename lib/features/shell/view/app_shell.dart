import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/get.dart';
import '../../../core/repository/crm_repository.dart';
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
/// The three data blocs live here, and the pages stay alive in an
/// [IndexedStack]. Switching tabs must not throw away a half-typed Ona thread
/// or refetch a board the user looked at four seconds ago — on a phone in a
/// lift that refetch is a spinner and nothing else.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _select(int value) {
    if (value != _index) setState(() => _index = value);
  }

  @override
  Widget build(BuildContext context) {
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
        BlocProvider<ListingsBloc>(
          create: (_) =>
              ListingsBloc(repository: repository)..add(const ListingsLoaded()),
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

  /// Kept alive, but only the visible one animates in.
  ///
  /// A cross-fade between two IndexedStack children would show both mid-way;
  /// this instead slides the incoming page a few pixels, which reads as
  /// "changed surface" without implying a spatial direction the tabs do not
  /// actually have.
  Widget get _body => IndexedStack(
        index: index,
        children: <Widget>[
          for (int i = 0; i < 3; i++)
            _PageFade(
              visible: i == index,
              child: const <Widget>[
                OnaView(),
                PipelineView(),
                ListingsView(),
              ][i],
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: (_) => Scaffold(
        backgroundColor: AppColors.paper,
        extendBody: true,
        body: _body,
        bottomNavigationBar: PillNavBar(index: index, onSelect: onSelect),
      ),
      tablet: (_) => _WideShell(index: index, onSelect: onSelect, body: _body),
      desktop: (_) => _WideShell(
        index: index,
        onSelect: onSelect,
        body: _body,
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
    this.extended = false,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final Widget body;
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
                  destinations: navDestinations
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
