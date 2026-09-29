import 'package:flutter/material.dart';

import '../tokens.dart';

/// One tab of the bottom navigation.
class HmNavTab {
  const HmNavTab({required this.icon, required this.label, this.selectedIcon, this.badgeCount = 0});

  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  /// A red count on the icon; nothing at all when zero.
  final int badgeCount;
}

/// HM/Navigation/BottomNavBar and PartnerNavBar: one bar, whatever tabs the
/// active role has. The tab sets live in `lib/routing/nav_tabs.dart`.
class HmBottomNav extends StatelessWidget {
  const HmBottomNav({super.key, required this.tabs, required this.currentIndex, required this.onSelected});

  final List<HmNavTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: HmColors.bgPrimary,
          indicatorColor: HmColors.brandPrimaryDark,
          height: 80,
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              size: 24,
              color: states.contains(WidgetState.selected) ? HmColors.textOnBrand : HmColors.textPrimary,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
              color: HmColors.textPrimary,
            ),
          ),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: HmColors.borderDefault))),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onSelected,
            destinations: [
              for (final tab in tabs)
                NavigationDestination(
                  icon: HmCountBadge(count: tab.badgeCount, child: Icon(tab.icon)),
                  selectedIcon: HmCountBadge(count: tab.badgeCount, child: Icon(tab.selectedIcon ?? tab.icon)),
                  label: tab.label,
                ),
            ],
          ),
        ),
      );
}

/// A count on an icon, and nothing at all when there is none to show.
class HmCountBadge extends StatelessWidget {
  const HmCountBadge({super.key, required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Badge(
      backgroundColor: HmColors.error,
      label: Text(count > 99 ? '99+' : '$count'),
      child: child,
    );
  }
}
