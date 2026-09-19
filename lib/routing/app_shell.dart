import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../design/tokens.dart';

/// The bottom navigation the signed-in app lives inside.
///
/// The badges come from the shared activity summary, so the number on the tab
/// and the list behind it cannot disagree — and one `invalidate` after an
/// action moves every badge at once.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(activitySummaryProvider).valueOrNull;
    final activityBadge = (summary?.openInquiries ?? 0) +
        (summary?.upcomingViewings ?? 0) +
        (summary?.paymentsAwaitingVerification ?? 0);

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        // `initialLocation: true` on a re-tap pops that tab back to its root,
        // which is what a person expects from tapping the tab they are on.
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            // "Favourite", per the design's bottom bar. The tab holds more
            // than saved listings now — active rents, enquiries and viewings
            // as well — so "Saved" was also describing about a quarter of what
            // is behind it.
            icon: _Badged(
              count: summary?.savedCount ?? 0,
              child: const Icon(Icons.favorite_outline),
            ),
            selectedIcon: const Icon(Icons.favorite),
            label: 'Favourite',
          ),
          NavigationDestination(
            icon: _Badged(count: activityBadge, child: const Icon(Icons.receipt_long_outlined)),
            selectedIcon: const Icon(Icons.receipt_long),
            label: 'Activity',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// A count on a tab icon, and nothing at all when there is none to show.
class _Badged extends StatelessWidget {
  const _Badged({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Badge(
      backgroundColor: HmColors.error,
      // Read aloud as a number rather than as decoration.
      label: Text(count > 99 ? '99+' : '$count'),
      child: child,
    );
  }
}
