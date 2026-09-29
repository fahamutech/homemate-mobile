import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/i18n/app_text.dart';
import '../core/providers.dart';
import '../design/widgets/hm_bottom_nav.dart';
import 'nav_tabs.dart';

/// The bottom navigation the signed-in customer app lives inside.
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

    return Scaffold(
      body: shell,
      bottomNavigationBar: HmBottomNav(
        tabs: customerTabs(
          context.text,
          savedCount: summary?.savedCount ?? 0,
          activityCount: (summary?.openInquiries ?? 0) + (summary?.paymentsAwaitingVerification ?? 0),
        ),
        currentIndex: shell.currentIndex,
        // `initialLocation: true` on a re-tap pops that tab back to its root,
        // which is what a person expects from tapping the tab they are on.
        onSelected: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
      ),
    );
  }
}
