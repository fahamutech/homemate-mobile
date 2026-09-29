import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/i18n/app_locale.dart';
import 'package:homemate_mobile/core/i18n/app_text.dart';
import 'package:homemate_mobile/design/widgets/hm_bottom_nav.dart';
import 'package:homemate_mobile/routing/nav_tabs.dart';

import 'widget_harness.dart';

void main() {
  const en = AppText(AppLocale.english);
  const sw = AppText(AppLocale.swahili);

  group('the tabs each role gets', () {
    test('customer: Home, Search, Favourite, Activity, Profile — with counts', () {
      final tabs = customerTabs(en, savedCount: 2, activityCount: 5);
      expect(tabs.map((t) => t.label), ['Home', 'Search', 'Favourite', 'Activity', 'Profile']);
      expect(tabs.map((t) => t.badgeCount), [0, 0, 2, 5, 0]);
    });

    test('broker: Home, Listings, Enquiries, Earnings, Profile', () {
      expect(brokerTabs(en, enquiryCount: 3).map((t) => t.label), ['Home', 'Listings', 'Enquiries', 'Earnings', 'Profile']);
      expect(brokerTabs(en, enquiryCount: 3)[2].badgeCount, 3);
    });

    test('landlord: Home, Homes, Tenants, Money, Profile', () {
      expect(landlordTabs(en).map((t) => t.label), ['Home', 'Homes', 'Tenants', 'Money', 'Profile']);
    });

    test('and in Kiswahili', () {
      expect(brokerTabs(sw).map((t) => t.label), ['Mwanzo', 'Matangazo', 'Maulizo', 'Mapato', 'Wasifu']);
      expect(landlordTabs(sw).map((t) => t.label), ['Mwanzo', 'Nyumba', 'Wapangaji', 'Pesa', 'Wasifu']);
    });
  });

  testWidgets('HmBottomNav draws the tabs it is given and reports taps', (tester) async {
    int? picked;
    await tester.pumpWidget(themed(Align(
      alignment: Alignment.bottomCenter,
      child: HmBottomNav(
        tabs: const [
          HmNavTab(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
          HmNavTab(icon: Icons.domain_rounded, label: 'Listings', badgeCount: 120),
          HmNavTab(icon: Icons.forum_outlined, label: 'Enquiries', badgeCount: 0),
        ],
        currentIndex: 0,
        onSelected: (index) => picked = index,
      ),
    )));
    expect(find.text('Listings'), findsOneWidget);
    expect(find.text('99+'), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    await tester.tap(find.text('Enquiries'));
    expect(picked, 2);
  });
}
