import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/i18n/app_locale.dart';
import 'package:homemate_mobile/core/i18n/app_text.dart';
import 'package:homemate_mobile/core/i18n/language_picker.dart';
import 'package:homemate_mobile/core/i18n/locale_controller.dart';
import 'package:homemate_mobile/core/i18n/locale_store.dart';
import 'package:homemate_mobile/core/i18n/translations.dart';
import 'package:homemate_mobile/features/auth/presentation/onboarding_screen.dart';

import 'support/fakes.dart';

/// The app speaks Kiswahili first.
///
/// These are here because "default language" is the kind of decision that
/// quietly reverts: somebody adds a `supportedLocales` entry, the device
/// setting starts winning again, and nobody notices until a customer in Dar es
/// Salaam opens an English app.
void main() {
  group('the catalogue', () {
    test('says the same things in both languages', () {
      // Throws, naming the missing keys, if a phrase was added in one language
      // and forgotten in the other.
      assertCatalogueIsComplete();
    });

    test('falls back to a real sentence, never to a key', () {
      const sw = AppText(AppLocale.swahili);
      expect(sw.getStarted, 'Anza sasa');
      expect(sw.navHome, 'Mwanzo');
    });

    test('fills placeholders', () {
      const en = AppText(AppLocale.english);
      expect(en.greeting('Asha'), 'Hi, Asha 👋');
      expect(en.unreadNotifications(3), '3 unread notifications');
      // No name is a real case — the profile step is skippable.
      expect(en.greeting(null), 'Hi, there 👋');
      expect(const AppText(AppLocale.swahili).greeting(null), 'Habari, karibu 👋');
    });
  });

  group('counts', () {
    test('one is singular, in both languages', () {
      const en = AppText(AppLocale.english);
      const sw = AppText(AppLocale.swahili);
      expect(en.listingMonths(1), '1 month');
      expect(en.listingMonths(2), '2 months');
      expect(sw.listingMonths(1), 'Mwezi 1');
      expect(sw.listingMonths(2), 'Miezi 2');
      expect(en.listingOpenEnquiries(1), '1 open enquiry');
      expect(en.listingOpenEnquiries(3), '3 open enquiries');
      expect(sw.listingOpenEnquiries(1), 'Ulizo 1 lililo wazi');
      expect(en.enquiriesPeople(1), '1 person');
      expect(sw.enquiriesPeople(1), 'Mtu 1');
      expect(en.enquiriesPeople(2), '2 people');
      expect(en.landlordConfirmMonths(1), '1 month');
      expect(en.tenancyLeaseMonths(1), '1 month');
      expect(sw.tenancyLeaseMonths(12), 'Miezi 12');
      // A count that is not a whole one is plural.
      expect(en.listingMonths(1.5), '1.5 months');
    });
  });

  test('no copy leans on a symbol a phone may lack a glyph for', () {
    // "→" needs a fallback font that Flutter web fetches at runtime; where it
    // cannot, the reader sees an empty box. Say it in words instead.
    for (final locale in AppLocale.values) {
      final withArrow = [for (final e in kTranslations[locale]!.entries) if (e.value.contains('→')) e.key];
      expect(withArrow, isEmpty, reason: '$locale');
    }
  });

  group('the default', () {
    test('is Kiswahili when nothing has been chosen', () async {
      final controller = LocaleController(InMemoryLocaleStore());
      addTearDown(controller.dispose);
      expect(controller.state, AppLocale.swahili);
    });

    test('is whatever was chosen last, once something has been', () async {
      final store = InMemoryLocaleStore(AppLocale.english);
      final controller = LocaleController(store);
      addTearDown(controller.dispose);

      // The restore is asynchronous, so the first frame is still Kiswahili.
      await Future<void>.delayed(Duration.zero);
      expect(controller.state, AppLocale.english);
    });

    test('remembers a change', () async {
      final store = InMemoryLocaleStore();
      final controller = LocaleController(store);
      addTearDown(controller.dispose);

      await controller.select(AppLocale.english);
      expect(await store.read(), AppLocale.english);
    });
  });

  group('onboarding', () {
    testWidgets('opens in Kiswahili and can be switched before signing in',
        (tester) async {
      final harness = TestHarness();
      await tester.pumpWidget(
        harness.wrap(const OnboardingScreen(), locale: AppLocale.swahili),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pata nyumba yako'), findsOneWidget);
      expect(find.text('Endelea'), findsOneWidget);

      // The language control is the first thing on the first screen.
      await tester.tap(find.byType(LanguageButton));
      await tester.pumpAndSettle();
      expect(find.text('Chagua lugha yako'), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.text('Find your home'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Pata nyumba yako'), findsNothing);
    });
  });
}
