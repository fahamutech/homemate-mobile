import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_text.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_note.dart';
import '../../roles/data/app_role.dart';
import '../../roles/presentation/role_copy.dart';
import 'partner_role_header.dart';

/// The partner home until T09 (broker) and T10 (landlord) fill it: the role
/// header, and where the role stands while it is not verified yet.
class PartnerHomePlaceholder extends ConsumerWidget {
  const PartnerHomePlaceholder({super.key, required this.role});

  final AppRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    final label = roleLabel(text, role);
    final status = ref.watch(roleControllerProvider).held(role)?.status ?? 'applied';
    final note = switch (status) {
      'active' => null,
      'pending_review' => text.partnerStatusPendingReview(label),
      'action_needed' => text.partnerStatusActionNeeded(label),
      _ => text.partnerStatusApplied(label),
    };

    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            PartnerRoleHeader(role: role),
            Padding(
              padding: const EdgeInsets.all(HmSpace.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (note != null) ...[
                    HmNote(text: note, tone: status == 'action_needed' ? HmNoteTone.warning : HmNoteTone.brand),
                    const SizedBox(height: HmSpace.xxl),
                  ],
                  Text(text.partnerComingSoon(label), style: HmText.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
