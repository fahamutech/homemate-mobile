import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_text.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_icon_box.dart';
import '../../../design/widgets/hm_note.dart';
import '../data/app_role.dart';
import 'role_copy.dart';

/// ROL-002 "Switch role": from the role chip on a partner home, or Profile.
/// Never asks for the PIN again; the router moves to the new role's shell.
Future<void> showSwitchRoleSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const SwitchRoleSheet(),
    );

class SwitchRoleSheet extends ConsumerStatefulWidget {
  const SwitchRoleSheet({super.key});

  @override
  ConsumerState<SwitchRoleSheet> createState() => _SwitchRoleSheetState();
}

class _SwitchRoleSheetState extends ConsumerState<SwitchRoleSheet> {
  AppRole? _switching;

  Future<void> _switchTo(AppRole role) async {
    setState(() => _switching = role);
    try {
      await ref.read(roleControllerProvider.notifier).open(role);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() => _switching = null);
        HmFeedback.failure(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final state = ref.watch(roleControllerProvider);
    final phone = ref.watch(authControllerProvider).customer?.phoneNumber ?? '';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(HmSpace.xxl, 0, HmSpace.xxl, HmSpace.section),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(text.switchRoleTitle, style: HmText.heading.copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: HmSpace.xs),
            Text(text.switchRoleSubtitle(phone), style: const TextStyle(fontSize: 13, height: 18 / 13, color: HmColors.textSecondary)),
            const SizedBox(height: HmSpace.xxl),
            for (final role in state.switchable) ...[
              _RoleRow(
                role: role,
                current: role == state.current,
                subtitle: role == state.current
                    ? text.switchRoleCurrent
                    : roleStatusLabel(text, state.held(role)?.status) ?? roleSummary(text, role),
                busy: _switching == role,
                onTap: role == state.current || _switching != null ? null : () => _switchTo(role),
              ),
              const SizedBox(height: HmSpace.md),
            ],
            const SizedBox(height: HmSpace.md),
            HmNote(text: text.switchRoleNote),
          ],
        ),
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({required this.role, required this.current, required this.subtitle, required this.busy, this.onTap});

  final AppRole role;
  final bool current;
  final String subtitle;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(HmRadius.md);
    return Material(
      color: current ? HmColors.brandSubtle : HmColors.bgPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: current ? HmColors.brandPrimary : HmColors.borderDefault, width: current ? 1.5 : 1),
      ),
      child: InkWell(
        key: ValueKey('switch-to-${role.name}'),
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(HmSpace.xl),
          child: Row(
            children: [
              HmIconBox(
                icon: roleIcon(role),
                size: 40,
                iconSize: 22,
                fill: current ? HmColors.bgPrimary : HmColors.brandSubtle,
              ),
              const SizedBox(width: HmSpace.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(roleLabel(context.text, role),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: HmColors.textPrimary)),
                    const SizedBox(height: HmSpace.xxs),
                    Text(subtitle,
                        style: TextStyle(fontSize: 12, color: current ? HmColors.brandPrimary : HmColors.textSecondary)),
                  ],
                ),
              ),
              if (busy)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              else
                Icon(
                  current ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                  size: 22,
                  color: current ? HmColors.brandPrimary : HmColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
