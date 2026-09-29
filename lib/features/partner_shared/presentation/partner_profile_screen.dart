import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_text.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_badge.dart';
import '../../../design/widgets/hm_list_tile.dart';
import '../../../design/widgets/hm_top_bar.dart';
import '../../roles/data/app_role.dart';
import '../../roles/presentation/role_copy.dart';
import '../../roles/presentation/switch_role_sheet.dart';
import 'profile/partner_account_rows.dart';

/// The partner Profile tab: who is signed in, in which role, how to switch
/// role (ROL-002) and how to sign out of every role on this phone.
class PartnerProfileScreen extends ConsumerWidget {
  const PartnerProfileScreen({super.key, required this.role, this.children = const []});

  final AppRole role;

  /// Role-specific rows T09/T10 add (payout details, documents…).
  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    final customer = ref.watch(authControllerProvider).customer;

    return Scaffold(
      appBar: HmTopBar(title: text.navProfile),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: HmSpace.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: HmSpace.xxl),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: HmColors.brandSubtle,
                  child: Text(customer?.initials ?? '#',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: HmColors.brandPrimary)),
                ),
                const SizedBox(width: HmSpace.xxl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer?.displayName ?? '', style: HmText.heading),
                      const SizedBox(height: HmSpace.xxs),
                      Text(customer?.phoneNumber ?? '', style: HmText.caption),
                      const SizedBox(height: HmSpace.xs),
                      HmBadge(label: roleLabel(text, role), tone: HmBadgeTone.primary, icon: roleIcon(role)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: HmSpace.huge),
          PartnerAccountRows(role: role),
          ...children,
          HmListTile(
            icon: Icons.swap_horiz_rounded,
            title: text.switchRoleTitle,
            onTap: () => showSwitchRoleSheet(context),
          ),
          HmListTile(
            icon: Icons.logout_rounded,
            title: text.partnerSignOut,
            destructive: true,
            trailingIcon: null,
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}
