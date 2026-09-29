import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/providers.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_async.dart';
import '../../../../design/widgets/hm_button.dart';
import '../../../../design/widgets/hm_note.dart';
import 'document_slot.dart';
import 'document_slot_card.dart';
import 'setup_frame.dart';

/// BRK-002b "Verify your identity" — and, with [ownership], LND-002's proof
/// of ownership. The documents belong to the person, so what a verified
/// customer already sent carries over.
class IdentityStep extends ConsumerWidget {
  const IdentityStep({super.key, required this.onDone, this.ownership = false});

  final VoidCallback onDone;
  final bool ownership;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    final identity = ref.watch(identityStatusProvider);
    const gap = SizedBox(height: HmSpace.xl);

    return SetupFrame(
      actions: [
        HmButton(label: text.continueLabel, onPressed: onDone),
        HmButton(label: text.partnerIdentityLater, style: HmButtonStyle.ghost, onPressed: onDone),
      ],
      children: [
        Text(ownership ? text.partnerOwnershipTitle : text.partnerIdentityTitle, style: HmText.title),
        const SizedBox(height: HmSpace.md),
        Text(ownership ? text.partnerOwnershipBody : text.partnerIdentityBody, style: HmText.body),
        const SizedBox(height: HmSpace.xxl),
        HmAsync(
          value: identity,
          data: (status) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!ownership && status.isVerified) ...[
                HmNote(text: text.partnerIdentityCarried, tone: HmNoteTone.success, icon: Icons.verified_user_outlined),
                gap,
              ],
              for (final (slot, optional) in ownership
                  ? [(DocumentSlot.titleDeed, false), (DocumentSlot.utilityBill, false)]
                  : [(DocumentSlot.id, false), (DocumentSlot.selfie, false), (DocumentSlot.tin, true), (DocumentSlot.licence, true)]) ...[
                DocumentSlotCard(slot: slot, identity: status, optional: optional),
                gap,
              ],
            ],
          ),
        ),
      ],
    );
  }
}
