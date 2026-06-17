import 'package:flutter/material.dart';

import '../home/home_view.dart';
import '../meetings/meetings_view.dart';
import '../pending_capture/pending_capture_view.dart';

class MainShellView extends StatefulWidget {
  const MainShellView({super.key});

  @override
  State<MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<MainShellView> {
  int _index = 0;

  static const List<Widget> _pages = <Widget>[
    HomeView(key: ValueKey<String>('home')),
    MeetingsView(key: ValueKey<String>('meetings')),
    PendingCaptureView(key: ValueKey<String>('captures')),
    _ProfileView(key: ValueKey<String>('profile')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          final Animation<Offset> slide = Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: _pages[_index],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x16000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: NavigationBar(
                height: 72,
                selectedIndex: _index,
                onDestinationSelected: (int value) {
                  if (value != _index) setState(() => _index = value);
                },
                destinations: const <NavigationDestination>[
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month_rounded),
                    label: 'Meetings',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.mic_none_rounded),
                    selectedIcon: Icon(Icons.mic_rounded),
                    label: 'Captures',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              tween: Tween<double>(begin: 0.85, end: 1),
              curve: Curves.easeOutBack,
              builder: (_, double value, Widget? child) => Transform.scale(scale: value, child: child),
              child: const CircleAvatar(
                radius: 44,
                child: Text('SP', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('Savin Padencherry', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ),
          const Center(child: Text('CTO · FocusChain Labs')),
          const SizedBox(height: 28),
          Card(
            child: Column(
              children: <Widget>[
                const ListTile(
                  leading: Icon(Icons.cloud_done_outlined),
                  title: Text('Connections'),
                  subtitle: Text('Calendar connected · CRM pending'),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.shield_outlined),
                  title: Text('Organisation & access'),
                  subtitle: Text('FocusChain Labs · Admin'),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('App build'),
                  subtitle: const Text('Mr. Rex Interactive Preview 0.4'),
                  trailing: Chip(
                    label: const Text('LIVE'),
                    backgroundColor: colors.primaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
