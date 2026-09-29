import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/providers.dart';
import '../../../../design/widgets/hm_badge.dart';
import '../../../../design/widgets/hm_list_tile.dart';
import '../../../../routing/routes.dart';
import '../../../roles/data/app_role.dart';
import '../../data/partner_providers.dart';
import '../payout_labels.dart';
import '../setup/setup_step.dart';

/// BRK-060 / LND-060: the partner's account on the Profile tab — details,
/// identity, where payouts go, the agreement and help — each leading to where
/// it is changed.
class PartnerAccountRows extends ConsumerWidget {
  const PartnerAccountRows({super.key, required this.role});

  final AppRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    final overview = ref.watch(applicationsProvider).valueOrNull;
    final profile = overview?.profile;
    final application = overview?.application(role.name);
    final reference = ref.watch(referenceDataProvider).valueOrNull;
    String bankName(String code) => reference?.banks.where((b) => b.code == code).map((b) => b.name).firstOrNull ?? code;
    final agreed = application?.agreementVersion != null && application?.agreementVersion == application?.currentAgreementVersion;

    return Column(children: [
      HmListTile(
        icon: Icons.person_outline_rounded,
        title: text.profileEditDetails,
        onTap: () => context.push(Routes.partnerSetup(role, step: SetupStep.details.name)),
      ),
      HmListTile(
        icon: Icons.badge_outlined,
        title: text.profileIdentity,
        badge: profile?.identityVerified ?? false ? HmBadge(label: text.enquiryIdVerified, tone: HmBadgeTone.success) : null,
        onTap: () => context.push(Routes.partnerSetup(role, step: SetupStep.identity.name)),
      ),
      HmListTile(
        icon: Icons.account_balance_wallet_outlined,
        title: text.profilePayout,
        value: profile?.payout == null ? null : payoutAccountLine(profile!.payout, bankName: bankName),
        onTap: () => context.push(profile?.payout == null
            ? Routes.partnerSetup(role, step: SetupStep.payout.name)
            : Routes.partnerPayouts(role)),
      ),
      HmListTile(
        icon: Icons.description_outlined,
        title: text.profileAgreement,
        value: agreed ? text.profileAgreementSigned : null,
        onTap: agreed ? null : () => context.push(Routes.partnerSetup(role, step: SetupStep.payout.name)),
      ),
      HmListTile(
        icon: Icons.help_outline_rounded,
        title: text.profileHelp,
        subtitle: text.profileHelpBody,
        trailingIcon: null,
      ),
    ]);
  }
}

