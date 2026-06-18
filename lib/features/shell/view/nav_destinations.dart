import 'package:flutter/material.dart';

/// A single navigation destination, shared by the bottom bar and the rail so
/// the tab set is defined once.
class NavItem {
  const NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const List<NavItem> navDestinations = <NavItem>[
  NavItem(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  NavItem(
    label: 'Leads',
    icon: Icons.people_outline_rounded,
    selectedIcon: Icons.people_rounded,
  ),
  NavItem(
    label: 'Meetings',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month_rounded,
  ),
  NavItem(
    label: 'Captures',
    icon: Icons.mic_none_rounded,
    selectedIcon: Icons.mic_rounded,
  ),
  NavItem(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
  ),
];
