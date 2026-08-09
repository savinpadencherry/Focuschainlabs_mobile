import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../nav_destinations.dart';

/// A floating pill navigation bar.
///
/// Three destinations, so each one can afford to say its name when selected
/// instead of relying on an icon alone. The selected item grows into a filled
/// pill and its label fades in; the others stay quiet. That gives the bar a
/// single, obvious focal point at any moment — which is the whole job of a
/// navigation bar and the thing a row of five identical icons cannot do.
///
/// Hand-built rather than a package: with three items the layout is trivial,
/// and owning the animation means the selection can move with the same easing
/// as everything else on screen.
class PillNavBar extends StatelessWidget {
  const PillNavBar({
    super.key,
    required this.index,
    required this.onSelect,
  });

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.34),
                blurRadius: 26,
                offset: const Offset(0, 12),
                spreadRadius: -6,
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              for (int i = 0; i < navDestinations.length; i++)
                _NavPill(
                  item: navDestinations[i],
                  selected: i == index,
                  onTap: () => onSelect(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The selected pill takes twice the width of an unselected one. Flex
    // rather than a fixed width so the bar fits any screen without measuring.
    return Expanded(
      flex: selected ? 2 : 1,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          height: 46,
          decoration: BoxDecoration(
            color: selected ? AppColors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  key: ValueKey<bool>(selected),
                  size: 21,
                  color: selected ? Colors.white : AppColors.paper2,
                ),
              ),
              // The label only exists while selected, and animates its own
              // width so the icon slides rather than jumping.
              ClipRect(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  widthFactor: selected ? 1 : 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: selected ? 1 : 0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
