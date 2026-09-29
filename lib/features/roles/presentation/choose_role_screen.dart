import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_text.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_badge.dart';
import '../../../design/widgets/hm_button.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_radio_card.dart';
import '../data/app_role.dart';
import '../domain/role_landing.dart';
import 'role_copy.dart';
import 'role_question_layout.dart';

/// ROL-001 "Choose how to continue" — after the PIN, for someone with more
/// than one role, unless "Always open as …" was ticked on this phone.
class ChooseRoleScreen extends ConsumerStatefulWidget {
  const ChooseRoleScreen({super.key});

  @override
  ConsumerState<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends ConsumerState<ChooseRoleScreen> {
  AppRole? _selected;
  bool _alwaysOpen = false;
  bool _busy = false;

  Future<void> _continue(AppRole role) async {
    setState(() => _busy = true);
    try {
      await ref.read(roleControllerProvider.notifier).chooseRole(role, alwaysOpen: _alwaysOpen);
    } catch (error) {
      if (mounted) HmFeedback.failure(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final state = ref.watch(roleControllerProvider);
    final name = ref.watch(authControllerProvider).customer?.fullName?.trim().split(RegExp(r'\s+')).first;
    final landing = state.landing;
    final selected = _selected ?? (landing is ChooseRole ? landing.preselected : AppRole.customer);
    final label = roleLabel(text, selected);

    return RoleQuestionLayout(
      title: (name == null || name.isEmpty) ? text.chooseRoleTitleNoName : text.chooseRoleTitle(name),
      subtitle: text.chooseRoleSubtitle,
      action: HmButton(label: text.chooseRoleContinueAs(label), busy: _busy, onPressed: () => _continue(selected)),
      children: [
        for (final role in state.switchable) ...[
          HmRadioCard(
            icon: roleIcon(role),
            title: roleLabel(text, role),
            subtitle: roleSummary(text, role),
            selected: selected == role,
            badge: switch (roleStatusLabel(text, state.held(role)?.status)) {
              final status? => HmBadge(label: status, tone: HmBadgeTone.warning),
              null => null,
            },
            onTap: () => setState(() => _selected = role),
          ),
          const SizedBox(height: HmSpace.xl),
        ],
        CheckboxListTile(
          value: _alwaysOpen,
          onChanged: (value) => setState(() => _alwaysOpen = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: HmColors.brandPrimary,
          title: Text(text.chooseRoleAlways(label), style: const TextStyle(fontSize: 14, color: HmColors.textBody)),
        ),
        const SizedBox(height: HmSpace.md),
        Text(
          text.chooseRoleHint,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: HmColors.textSecondary),
        ),
      ],
    );
  }
}
