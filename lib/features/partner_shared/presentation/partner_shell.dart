import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_text.dart';
import '../../../design/widgets/hm_bottom_nav.dart';
import '../../../routing/nav_tabs.dart';
import '../../roles/data/app_role.dart';

/// The broker or landlord app: the same bottom bar as the customer's, with
/// the role's own five tabs.
class PartnerShell extends StatelessWidget {
  const PartnerShell({super.key, required this.role, required this.shell});

  final AppRole role;
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: shell,
        bottomNavigationBar: HmBottomNav(
          tabs: role == AppRole.broker ? brokerTabs(context.text) : landlordTabs(context.text),
          currentIndex: shell.currentIndex,
          onSelected: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
        ),
      );
}
