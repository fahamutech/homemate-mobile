import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_text.dart';
import '../../../core/providers.dart';
import '../../../design/widgets/hm_role_header.dart';
import '../../roles/data/app_role.dart';
import '../../roles/presentation/role_copy.dart';
import '../../roles/presentation/switch_role_sheet.dart';

/// HmRoleHeader wired to the session: the person's name, the role in use,
/// and the chip that opens ROL-002 when there is another role to go to.
class PartnerRoleHeader extends ConsumerWidget {
  const PartnerRoleHeader({super.key, required this.role, this.onNotifications});

  final AppRole role;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    final customer = ref.watch(authControllerProvider).customer;
    final canSwitch = ref.watch(roleControllerProvider).switchable.length > 1;
    final firstName = customer?.fullName?.trim().split(RegExp(r'\s+')).first;

    return HmRoleHeader(
      greeting: text.greeting(firstName),
      initials: customer?.initials ?? '#',
      roleLabel: roleLabel(text, role),
      roleIcon: roleIcon(role),
      onSwitchRole: canSwitch ? () => showSwitchRoleSheet(context) : null,
      onNotifications: onNotifications,
    );
  }
}
