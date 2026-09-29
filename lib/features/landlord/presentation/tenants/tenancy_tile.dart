import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_badge.dart';
import '../../../../design/widgets/hm_button.dart';
import '../../../../design/widgets/hm_money.dart';
import '../../../../design/widgets/hm_section.dart';
import '../../../../routing/routes.dart';
import '../../../partner_shared/presentation/enquiries/customer_avatar_initials.dart';
import '../../data/tenancy.dart';
import 'tenancy_actions.dart';
import 'tenancy_copy.dart';

/// One tenancy on LND-030: the tenant, the home, the rent and the date that
/// matters — with the move-in offered only while the tenant is moving in.
class TenancyTile extends ConsumerWidget {
  const TenancyTile({super.key, required this.tenancy});

  final Tenancy tenancy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    final when = tenancyWhen(text, tenancy);
    return InkWell(
      key: ValueKey('tenancy-${tenancy.id}'),
      onTap: () => context.push(Routes.landlordTenancy(tenancy.id)),
      child: HmCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            InitialsAvatar(name: tenancy.tenantName),
            const SizedBox(width: HmSpace.xl),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tenancy.tenantName, style: HmText.label.copyWith(fontSize: 16)),
                Text(tenancy.propertyTitle, style: HmText.caption),
              ]),
            ),
            HmBadge(label: tenancyStageLabel(text, tenancy.stage), tone: tenancyStageTone(tenancy.stage)),
          ]),
          const SizedBox(height: HmSpace.md),
          Row(children: [
            Expanded(child: Text(text.tenantsPerMonth(HmMoney.format(tenancy.monthlyRent, currency: tenancy.currency)), style: HmText.body)),
            if (when != null) Text(when, style: HmText.caption),
          ]),
          if (tenancy.canConfirmMoveIn) ...[
            const SizedBox(height: HmSpace.xl),
            HmButton(
              label: text.tenancyConfirmMoveIn,
              icon: Icons.key_outlined,
              size: HmButtonSize.medium,
              onPressed: () => confirmMoveIn(context, ref, tenancy),
            ),
          ],
        ]),
      ),
    );
  }
}
