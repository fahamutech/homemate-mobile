import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_text.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_badge.dart';
import '../../../design/widgets/hm_button.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_note.dart';
import '../../../design/widgets/hm_radio_card.dart';
import '../../../design/widgets/hm_top_bar.dart';
import '../data/app_role.dart';
import 'role_copy.dart';

/// ROL-004 "Earn with HomeMate": a customer adds a partner role to the same
/// account. Continue opens that role's shell, which runs its setup.
class EarnScreen extends ConsumerStatefulWidget {
  const EarnScreen({super.key});

  @override
  ConsumerState<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends ConsumerState<EarnScreen> {
  AppRole? _selected;
  bool _busy = false;

  Future<void> _continue(AppRole role) async {
    setState(() => _busy = true);
    try {
      await ref.read(roleControllerProvider.notifier).open(role);
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
    final options = [
      (AppRole.broker, text.earnBrokerTitle, text.earnBrokerBody, [text.earnBrokerPoint1, text.earnBrokerPoint2, text.earnBrokerPoint3]),
      (AppRole.landlord, text.roleLandlord, text.earnLandlordBody, [text.earnLandlordPoint1, text.earnLandlordPoint2, text.earnLandlordPoint3]),
    ];
    // A role already on the account is shown, but switched to from ROL-002.
    final open = [for (final option in options) if (state.held(option.$1) == null) option.$1];
    final selected = _selected ?? (open.isEmpty ? null : open.first);

    return Scaffold(
      backgroundColor: HmColors.bgPrimary,
      appBar: HmTopBar(
        title: text.earnTitle,
        backTooltip: text.back,
        onBack: () => context.canPop() ? context.pop() : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(HmSpace.xxl),
        children: [
          Text(text.roleUseTitle, style: HmText.title),
          const SizedBox(height: HmSpace.xxl),
          Text(text.earnSubtitle, style: HmText.body.copyWith(height: 22 / 15)),
          const SizedBox(height: HmSpace.xxl),
          for (final (role, title, body, points) in options) ...[
            HmRadioCard(
              icon: roleIcon(role),
              title: title,
              subtitle: body,
              details: points,
              selected: selected == role,
              badge: state.held(role) == null ? null : HmBadge(label: text.earnAlreadyHeld, tone: HmBadgeTone.neutral),
              onTap: state.held(role) == null ? () => setState(() => _selected = role) : null,
            ),
            const SizedBox(height: HmSpace.xxl),
          ],
          HmNote(text: text.earnNote),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(HmSpace.xxl, HmSpace.xxl, HmSpace.xxl, HmSpace.xxl),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: HmColors.borderDefault))),
          child: HmButton(
            label: text.continueLabel,
            busy: _busy,
            onPressed: selected == null ? null : () => _continue(selected),
          ),
        ),
      ),
    );
  }
}
