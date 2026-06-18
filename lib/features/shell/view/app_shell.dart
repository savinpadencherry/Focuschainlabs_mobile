import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/utils/responsive.dart';
import '../../capture/view/capture_view.dart';
import '../../home/view/home_page.dart';
import '../../leads/view/leads_page.dart';
import '../../meetings/view/meetings_page.dart';
import '../../pending/view/pending_page.dart';
import '../../profile/view/profile_page.dart';
import 'nav_destinations.dart';

/// Root authenticated surface. Switches between a bottom navigation bar
/// (phone) and a side navigation rail (tablet / web) so the same screens feel
/// native at every breakpoint.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const List<Widget> _pages = <Widget>[
    HomePage(key: ValueKey<String>('home')),
    LeadsPage(key: ValueKey<String>('leads')),
    MeetingsPage(key: ValueKey<String>('meetings')),
    PendingPage(key: ValueKey<String>('pending')),
    ProfilePage(key: ValueKey<String>('profile')),
  ];

  void _select(int value) {
    if (value != _index) setState(() => _index = value);
  }

  Widget get _body => AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) =>
            FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.02, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: _pages[_index],
      );

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: (_) => _MobileShell(
        index: _index,
        onSelect: _select,
        body: _body,
      ),
      tablet: (_) => _WideShell(
        index: _index,
        onSelect: _select,
        body: _body,
        extended: false,
      ),
      desktop: (_) => _WideShell(
        index: _index,
        onSelect: _select,
        body: _body,
        extended: true,
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.index,
    required this.onSelect,
    required this.body,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: body,
      floatingActionButton: const _TalkToRexFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: CurvedNavigationBar(
        index: index,
        height: 64,
        color: AppColors.surface,
        buttonBackgroundColor: AppColors.green,
        backgroundColor: Colors.transparent,
        animationCurve: AppMotion.ease,
        animationDuration: const Duration(milliseconds: 380),
        onTap: onSelect,
        items: <Widget>[
          for (int i = 0; i < navDestinations.length; i++)
            Icon(
              i == index ? navDestinations[i].selectedIcon : navDestinations[i].icon,
              color: i == index ? Colors.white : AppColors.inkSoft,
              size: 26,
            ),
        ],
      ),
    );
  }
}

class _WideShell extends StatelessWidget {
  const _WideShell({
    required this.index,
    required this.onSelect,
    required this.body,
    required this.extended,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final Widget body;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      floatingActionButton: const _TalkToRexFab(),
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
          child: const Text('🦖', style: TextStyle(fontSize: 18)),
        ),
        if (extended) ...<Widget>[
          const SizedBox(width: 10),
          const Text('Mr. Rex',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ],
    );
  }
}

class _TalkToRexFab extends StatelessWidget {
  const _TalkToRexFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => CaptureView.open(context),
      icon: const Icon(Icons.mic_rounded),
      label: const Text('Talk to Rex'),
    );
  }
}
