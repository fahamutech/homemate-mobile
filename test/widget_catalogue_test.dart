import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/i18n/app_locale.dart';
import 'package:homemate_mobile/core/i18n/locale_controller.dart';
import 'package:homemate_mobile/core/providers.dart';
import 'package:homemate_mobile/design/widgets/hm_bottom_nav.dart';
import 'package:homemate_mobile/design/widgets/hm_button.dart';
import 'package:homemate_mobile/features/dev/widget_catalogue_screen.dart';
import 'package:homemate_mobile/routing/app_router.dart';

import 'support/fakes.dart';

/// `/dev/widgets`: every shared widget, in both languages, reachable in a
/// debug build without signing in.
void main() {
  // The catalogue shows a busy button, whose spinner never settles, so these
  // tests pump for a fixed time instead of `pumpAndSettle`.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> scrollThrough(WidgetTester tester) async {
    // Drags to the end, which builds (and so lays out) every section once;
    // an overflow anywhere fails the test.
    for (var i = 0; i < 30; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();
    }
  }

  for (final locale in AppLocale.values) {
    testWidgets('lays out every section in ${locale.englishName}', (tester) async {
      tester.view.physicalSize = TestHarness.phone * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final harness = TestHarness(locale: locale);
      await tester.pumpWidget(harness.wrap(const WidgetCatalogueScreen()));
      await settle(tester);

      final title = locale == AppLocale.swahili ? 'Katalogi ya vipengele' : 'Widget catalogue';
      expect(find.text(title), findsOneWidget);
      expect(find.byType(HmButton), findsWidgets);
      await scrollThrough(tester);
      expect(find.byType(HmBottomNav), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('switching language re-renders the page', (tester) async {
    tester.view.physicalSize = TestHarness.phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final harness = TestHarness();
    await tester.pumpWidget(harness.wrap(const WidgetCatalogueScreen()));
    await settle(tester);
    expect(find.text('Buttons'), findsOneWidget);

    await harness.container!.read(localeProvider.notifier).select(AppLocale.swahili);
    await settle(tester);
    expect(find.text('Vitufe'), findsOneWidget);
  });

  testWidgets('the route opens without a session in a debug build', (tester) async {
    final harness = TestHarness();
    final container = ProviderContainer(overrides: harness.overrides);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).restore();

    final router = container.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: testApp(router)));
    await settle(tester);

    router.go(Routes.devWidgets);
    await settle(tester);
    expect(router.state.matchedLocation, Routes.devWidgets);
    expect(find.byType(WidgetCatalogueScreen), findsOneWidget);
  });
}
