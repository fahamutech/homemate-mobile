import 'package:flutter/material.dart';

import '../core/i18n/app_text.dart';
import '../design/widgets/hm_bottom_nav.dart';

/// The five tabs each role's shell shows, in order. The branch order of each
/// shell route follows these lists.

List<HmNavTab> customerTabs(AppText text, {int savedCount = 0, int activityCount = 0}) => [
      HmNavTab(icon: Icons.home_outlined, selectedIcon: Icons.home, label: text.navHome),
      HmNavTab(icon: Icons.search_outlined, selectedIcon: Icons.search, label: text.navSearch),
      // "Favourite", per the design's bottom bar. The tab holds more than
      // saved listings — active rents and enquiries as well.
      HmNavTab(
        icon: Icons.favorite_outline,
        selectedIcon: Icons.favorite,
        label: text.navFavourite,
        badgeCount: savedCount,
      ),
      HmNavTab(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        label: text.navActivity,
        badgeCount: activityCount,
      ),
      HmNavTab(icon: Icons.person_outline, selectedIcon: Icons.person, label: text.navProfile),
    ];

List<HmNavTab> brokerTabs(AppText text, {int enquiryCount = 0}) => [
      HmNavTab(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: text.navHome),
      HmNavTab(icon: Icons.domain_rounded, label: text.navListings),
      HmNavTab(icon: Icons.forum_outlined, selectedIcon: Icons.forum_rounded, label: text.navEnquiries, badgeCount: enquiryCount),
      HmNavTab(icon: Icons.account_balance_wallet_outlined, selectedIcon: Icons.account_balance_wallet_rounded, label: text.navEarnings),
      HmNavTab(icon: Icons.person_outline, selectedIcon: Icons.person_rounded, label: text.navProfile),
    ];

List<HmNavTab> landlordTabs(AppText text, {int homesCount = 0}) => [
      HmNavTab(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: text.navHome),
      HmNavTab(icon: Icons.house_outlined, selectedIcon: Icons.house_rounded, label: text.navHomes, badgeCount: homesCount),
      HmNavTab(icon: Icons.people_outline, selectedIcon: Icons.people_rounded, label: text.navTenants),
      HmNavTab(icon: Icons.payments_outlined, selectedIcon: Icons.payments_rounded, label: text.navMoney),
      HmNavTab(icon: Icons.person_outline, selectedIcon: Icons.person_rounded, label: text.navProfile),
    ];
