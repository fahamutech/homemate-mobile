import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_text.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_list_tile.dart';
import '../../../routing/routes.dart';
import '../data/app_role.dart';
import 'switch_role_sheet.dart';

/// The customer profile's "Work with HomeMate" section (ROL-003): "Earn with
/// HomeMate" while a partner role is still missing, and "Switch role" once
/// there is another role to switch to.
class WorkWithHomeMateSection extends ConsumerWidget {
  const WorkWithHomeMateSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    final state = ref.watch(roleControllerProvider);
    final missingPartnerRole = state.held(AppRole.broker) == null || state.held(AppRole.landlord) == null;
    final canSwitch = state.switchable.length > 1;
    if (!missingPartnerRole && !canSwitch) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(text.earnSection, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: HmColors.textSecondary)),
        const SizedBox(height: HmSpace.md),
        if (missingPartnerRole)
          Container(
            decoration: BoxDecoration(
              color: HmColors.brandSubtle,
              borderRadius: BorderRadius.circular(HmRadius.md),
              border: Border.all(color: HmColors.brandBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: HmListTile(
              icon: Icons.add_business_rounded,
              boxed: true,
              title: text.earnTitle,
              subtitle: text.earnEntryBody,
              onTap: () => context.push(Routes.earn),
            ),
          ),
        if (canSwitch)
          HmListTile(
            icon: Icons.swap_horiz_rounded,
            title: text.switchRoleTitle,
            onTap: () => showSwitchRoleSheet(context),
          ),
        const SizedBox(height: HmSpace.huge),
      ],
    );
  }
}
