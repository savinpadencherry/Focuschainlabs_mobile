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

/// The tab set for a tenant.
///
/// Listings only exists for a real-estate workspace — a B2B SaaS tenant has no
/// property inventory, and a tab that opens an empty tool about someone else's
/// business is worse than one tab fewer.
List<NavItem> navDestinationsFor({required bool showListings}) => <NavItem>[
      navDestinations[0],
      navDestinations[1],
      if (showListings) navDestinations[2],
    ];

/// The full set, in the order a day runs: ask what is waiting, work the
/// pipeline, find a property.
///
/// Profile is deliberately not here. It is somewhere you go once a month, and
/// spending a quarter of the navigation bar on it would push the things people
/// use all day into a narrower space. It lives behind the avatar in each
/// surface's header instead.
const List<NavItem> navDestinations = <NavItem>[
  NavItem(
    label: 'Ona',
    icon: Icons.auto_awesome_outlined,
    selectedIcon: Icons.auto_awesome_rounded,
  ),
  NavItem(
    label: 'Pipeline',
    icon: Icons.view_kanban_outlined,
    selectedIcon: Icons.view_kanban_rounded,
  ),
  NavItem(
    label: 'Listings',
    icon: Icons.apartment_outlined,
    selectedIcon: Icons.apartment_rounded,
  ),
];
