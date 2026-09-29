import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_text.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_button.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_note.dart';
import '../../../design/widgets/hm_radio_card.dart';
import '../data/app_role.dart';
import 'role_copy.dart';
import 'role_question_layout.dart';

/// AUTH-001 "How will you use HomeMate?" — once per new account, right after
/// Create PIN. The pick decides which setup runs next; the router follows.
class RoleUseScreen extends ConsumerStatefulWidget {
  const RoleUseScreen({super.key});

  @override
  ConsumerState<RoleUseScreen> createState() => _RoleUseScreenState();
}

class _RoleUseScreenState extends ConsumerState<RoleUseScreen> {
  AppRole _selected = AppRole.customer;
  bool _busy = false;

  Future<void> _continue() async {
    setState(() => _busy = true);
    try {
      await ref.read(roleControllerProvider.notifier).chooseUse(_selected);
    } catch (error) {
      if (mounted) HmFeedback.failure(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final options = [
      (AppRole.customer, text.roleUseCustomerTitle, text.roleUseCustomerBody),
      (AppRole.broker, text.roleUseBrokerTitle, text.roleUseBrokerBody),
      (AppRole.landlord, text.roleUseLandlordTitle, text.roleUseLandlordBody),
    ];

    return RoleQuestionLayout(
      title: text.roleUseTitle,
      subtitle: text.roleUseSubtitle,
      action: HmButton(label: text.continueLabel, busy: _busy, onPressed: _continue),
      children: [
        for (final (role, title, body) in options) ...[
          HmRadioCard(
            icon: roleIcon(role),
            title: title,
            subtitle: body,
            selected: _selected == role,
            onTap: () => setState(() => _selected = role),
          ),
          const SizedBox(height: HmSpace.xl),
        ],
        const SizedBox(height: HmSpace.md),
        HmNote(text: text.roleUseNote),
      ],
    );
  }
}
