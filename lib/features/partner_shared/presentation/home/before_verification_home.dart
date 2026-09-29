import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/providers.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_badge.dart';
import '../../../../design/widgets/hm_button.dart';
import '../../../../design/widgets/hm_section.dart';
import '../../../../routing/routes.dart';
import '../../../roles/data/app_role.dart';
import '../../../roles/presentation/role_copy.dart';
import '../../data/partner_application.dart';
import '../../data/partner_providers.dart';
import '../partner_role_header.dart';
import '../payout_labels.dart';
import '../setup/document_slot.dart';

/// BRK-010b / LND-010b: the home before the role is verified — a banner for
/// where the application stands, the "Get started" checklist, and drafting
/// (sending for review waits for verification).
class BeforeVerificationHome extends ConsumerWidget {
  const BeforeVerificationHome({super.key, required this.role, required this.overview});

  final AppRole role;
  final ApplicationsOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    final application = overview.application(role.name);
    final identity = ref.watch(identityStatusProvider).valueOrNull;
    final listings = ref.watch(partnerListingsProvider(null)).valueOrNull ?? const [];
    final label = roleLabel(text, role);

    final (title, body, fill, border, colour, icon, target) = switch (application.status) {
      'pending_review' => (
          text.partnerHomeVerifyingTitle,
          text.partnerHomeVerifyingBody,
          HmColors.orangeBg,
          HmColors.orangeBorder,
          HmColors.orangeText,
          Icons.hourglass_top_rounded,
          Routes.partnerApplication(role),
        ),
      'action_needed' => (
          text.partnerHomeActionTitle,
          text.partnerStatusActionNeeded(label),
          HmColors.redBg,
          HmColors.error,
          HmColors.redText,
          Icons.error_outline_rounded,
          Routes.partnerApplication(role),
        ),
      _ => (
          text.partnerHomeSetupTitle,
          text.partnerStatusApplied(label),
          HmColors.brandSubtle,
          HmColors.brandBorder,
          HmColors.brandPrimaryDark,
          Icons.edit_note_rounded,
          Routes.partnerSetup(role, step: _resumeStep(application)),
        ),
    };

    final identityState = identity == null
        ? 'missing'
        : [documentState(identity, DocumentSlot.id), documentState(identity, DocumentSlot.selfie)].contains('missing')
            ? 'missing'
            : application.isDone('identity') && overview.profile.identityVerified
                ? 'verified'
                : 'pending';

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        PartnerRoleHeader(role: role),
        Padding(
          padding: const EdgeInsets.all(HmSpace.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                key: const ValueKey('verification-banner'),
                onTap: () => context.push(target),
                borderRadius: BorderRadius.circular(HmRadius.md),
                child: Container(
                  padding: const EdgeInsets.all(HmSpace.xxl),
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(HmRadius.md),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(icon, size: 18, color: colour),
                        const SizedBox(width: HmSpace.md),
                        Expanded(child: Text(title, style: HmText.label.copyWith(fontSize: 15, color: colour))),
                      ]),
                      const SizedBox(height: HmSpace.md),
                      Text(body, style: HmText.body.copyWith(fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: HmSpace.huge),
              HmSectionHeader(title: text.partnerHomeGetStarted),
              HmCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ChecklistRow(
                      number: 1,
                      done: application.isDone('details'),
                      title: text.partnerStepDetails,
                      subtitle: text.partnerCheckDetailsSub,
                      onTap: () => context.push(Routes.partnerSetup(role, step: 'details')),
                    ),
                    _ChecklistRow(
                      number: 2,
                      done: identityState == 'verified',
                      title: text.partnerCheckIdentityTitle,
                      subtitle: identityState == 'missing' ? text.partnerCheckIdentityTodo : text.partnerCheckIdentityReviewing,
                      badge: identityState == 'pending' ? HmBadge(label: text.partnerDocInReview, tone: HmBadgeTone.warning) : null,
                      onTap: () => context.push(Routes.partnerSetup(role, step: 'identity')),
                    ),
                    _ChecklistRow(
                      number: 3,
                      done: application.isDone('payout'),
                      title: text.partnerReviewPayout,
                      subtitle: overview.profile.payout == null
                          ? text.partnerCheckPayoutTodo
                          : payoutAccountLine(overview.profile.payout),
                      onTap: () => context.push(Routes.partnerSetup(role, step: 'payout')),
                    ),
                    _ChecklistRow(
                      number: 4,
                      done: listings.isNotEmpty,
                      title: text.partnerCheckFirstHomeTitle,
                      subtitle: text.partnerCheckFirstHomeSub,
                      last: true,
                      onTap: () => context.push(Routes.partnerListingNew(role)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: HmSpace.huge),
              HmButton(
                label: text.partnerHomeDraftListing,
                icon: Icons.add_home_outlined,
                onPressed: application.canDraftListings ? () => context.push(Routes.partnerListingNew(role)) : null,
              ),
              if (!application.canDraftListings) ...[
                const SizedBox(height: HmSpace.md),
                HmButton(
                  label: text.partnerHomeContinueSetup,
                  style: HmButtonStyle.outline,
                  onPressed: () => context.push(Routes.partnerSetup(role, step: _resumeStep(application))),
                ),
              ],
              const SizedBox(height: HmSpace.section),
              const Icon(Icons.forum_outlined, size: 32, color: HmColors.textTertiary),
              const SizedBox(height: HmSpace.md),
              Text(text.partnerHomeEnquiriesEmpty, textAlign: TextAlign.center, style: HmText.caption.copyWith(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  static String? _resumeStep(PartnerApplication application) => switch (application.nextStep) {
        null => null,
        'agreement' => 'payout',
        final step => step,
      };
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.number,
    required this.done,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.last = false,
  });

  final int number;
  final bool done;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? badge;
  final bool last;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(HmSpace.xl),
          decoration: BoxDecoration(
            border: last ? null : const Border(bottom: BorderSide(color: HmColors.borderDefault)),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: done ? HmColors.success : HmColors.surfaceInput, shape: BoxShape.circle),
                child: done
                    ? const Icon(Icons.check_rounded, size: 16, color: HmColors.textOnBrand)
                    : Text('$number', style: HmText.label.copyWith(color: HmColors.textSecondary)),
              ),
              const SizedBox(width: HmSpace.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: HmText.label.copyWith(fontSize: 15)),
                    const SizedBox(height: HmSpace.xxs),
                    Text(subtitle, style: HmText.caption),
                  ],
                ),
              ),
              if (badge != null) badge!,
            ],
          ),
        ),
      );
}
