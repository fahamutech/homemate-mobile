import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/providers.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_async.dart';
import '../../../../design/widgets/hm_badge.dart';
import '../../../../design/widgets/hm_button.dart';
import '../../../../design/widgets/hm_feedback.dart';
import '../../../../design/widgets/hm_key_value.dart';
import '../../../../design/widgets/hm_money.dart';
import '../../../../design/widgets/hm_note.dart';
import '../../../../design/widgets/hm_section.dart';
import '../../../../design/widgets/hm_timeline_step.dart';
import '../../../../design/widgets/hm_top_bar.dart';
import '../../../../routing/routes.dart';
import '../../../roles/data/app_role.dart';
import '../../data/partner_listing.dart';
import '../../data/partner_providers.dart';
import '../partner_photo.dart';
import 'listing_broker_card.dart';
import 'listing_status.dart';
import 'wizard/wizard_step.dart';

/// BRK-021: one listing — HomeMate's note when changes are asked for, the
/// summary, the history, and what can be done with it now.
class PartnerListingScreen extends ConsumerWidget {
  const PartnerListingScreen({super.key, required this.role, required this.listingId});

  final AppRole role;
  final String listingId;

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final text = context.text;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(text.listingArchiveConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(text.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(text.listingArchive, style: const TextStyle(color: HmColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(listingsRepositoryProvider).archive(listingId);
      ref.invalidate(partnerListingProvider(listingId));
      ref.invalidate(partnerListingsProvider);
      if (context.mounted) HmFeedback.success(context, text.listingArchived);
    } catch (error) {
      if (context.mounted) HmFeedback.failure(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    final listing = ref.watch(partnerListingProvider(listingId));
    final loaded = listing.valueOrNull;

    return Scaffold(
      backgroundColor: HmColors.bgSecondary,
      appBar: HmTopBar(
        title: loaded?.title ?? '',
        onBack: () => context.canPop() ? context.pop() : context.go(Routes.partnerListings(role)),
        backTooltip: text.back,
      ),
      body: HmAsync<PartnerListing>(
        value: listing,
        onRetry: () => ref.invalidate(partnerListingProvider(listingId)),
        data: (listing) => _Body(role: role, listing: listing, onArchive: () => _archive(context, ref)),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.role, required this.listing, required this.onArchive});

  final AppRole role;
  final PartnerListing listing;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final day = DateFormat('d MMM');
    final changes = listing.status == 'changes_requested';
    final rejected = listing.status == 'rejected';
    final live = listing.status == 'approved' || listing.status == 'rented';
    final landlord = listing.landlord;

    final history = [
      (text.listingHistoryCreated, listing.createdAt, HmStepState.done),
      if (listing.submittedAt != null) (text.listingHistorySent, listing.submittedAt, HmStepState.done),
      if (changes) (text.listingHistoryChanges, listing.reviewedAt, HmStepState.current),
      if (rejected) (text.listingHistoryRejected, listing.reviewedAt, HmStepState.blocked),
      (text.listingHistoryLive, live ? listing.reviewedAt : null, live ? HmStepState.done : HmStepState.upcoming),
    ];

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(HmSpace.xxl),
            children: [
              if (listing.referenceCode != null) Text(listing.referenceCode!, style: HmText.caption),
              const SizedBox(height: HmSpace.md),
              if (listing.photos.isNotEmpty)
                SizedBox(height: 180, child: PartnerPhoto(url: listing.photos.first.url ?? '/app/media/${listing.photos.first.id}/raw', radius: HmRadius.md)),
              const SizedBox(height: HmSpace.xl),
              Align(
                alignment: Alignment.centerLeft,
                child: HmBadge(label: listingStatusLabel(text, listing.status), tone: listingStatusTone(listing.status)),
              ),
              const SizedBox(height: HmSpace.xl),
              if ((changes || rejected) && listing.rejectionReason != null) ...[
                Container(
                  padding: const EdgeInsets.all(HmSpace.xxl),
                  decoration: BoxDecoration(
                    color: HmColors.orangeBg,
                    borderRadius: BorderRadius.circular(HmRadius.md),
                    border: Border.all(color: HmColors.orangeBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.edit_note_rounded, size: 18, color: HmColors.orangeText),
                        const SizedBox(width: HmSpace.md),
                        Expanded(
                          child: Text(
                            changes ? text.listingChangesTitle : text.listingStatusRejected,
                            style: HmText.label.copyWith(fontSize: 15, color: HmColors.orangeText),
                          ),
                        ),
                        if (listing.reviewedAt != null) Text(day.format(listing.reviewedAt!), style: HmText.caption),
                      ]),
                      const SizedBox(height: HmSpace.xl),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(HmSpace.xl),
                        decoration: BoxDecoration(color: HmColors.bgPrimary, borderRadius: BorderRadius.circular(HmRadius.sm)),
                        child: Text(listing.rejectionReason!, style: HmText.body.copyWith(color: HmColors.textPrimary)),
                      ),
                      const SizedBox(height: HmSpace.md),
                      Text(text.listingFromReview, style: HmText.caption.copyWith(color: HmColors.orangeText)),
                    ],
                  ),
                ),
                const SizedBox(height: HmSpace.xxl),
              ],
              if (landlord?.confirmationStatus == 'disputed') ...[
                HmNote(text: text.listingLandlordDisputed(landlord!.disputeReason ?? ''), tone: HmNoteTone.warning),
                const SizedBox(height: HmSpace.xxl),
              ] else if (role == AppRole.broker && landlord?.confirmationStatus == 'pending') ...[
                HmNote(text: text.listingLandlordPending, tone: HmNoteTone.info),
                const SizedBox(height: HmSpace.xxl),
              ],
              if (role == AppRole.landlord && ListingBrokerCard.shows(listing)) ...[
                ListingBrokerCard(listing: listing),
                const SizedBox(height: HmSpace.xxl),
              ],
              HmCard(
                title: text.listingSummary,
                child: Column(
                  children: [
                    HmKeyValue(label: text.listingRent, value: text.listingRentPerMonth(HmMoney.format(listing.price)), emphasis: HmKeyValueEmphasis.strong),
                    HmKeyValue(
                      label: text.listingPaymentMode,
                      value: text.frequencyEvery(frequencyLabel(text, listing.paymentFrequency, customMonths: listing.customPaymentMonths).toLowerCase()),
                      emphasis: HmKeyValueEmphasis.strong,
                    ),
                    HmKeyValue(label: text.listingDeposit, value: text.listingMonths(listing.depositMonths.round()), emphasis: HmKeyValueEmphasis.strong),
                    if (listing.availableFrom != null)
                      HmKeyValue(
                        label: text.listingAvailableFrom,
                        value: DateFormat('d MMM yyyy').format(listing.availableFrom!),
                        emphasis: HmKeyValueEmphasis.strong,
                      ),
                    if (landlord != null)
                      HmKeyValue(label: text.listingLandlord, value: landlord.name ?? '', emphasis: HmKeyValueEmphasis.strong),
                  ],
                ),
              ),
              const SizedBox(height: HmSpace.xxl),
              HmCard(
                title: text.listingHistory,
                child: Column(
                  children: [
                    for (final (index, (title, at, state)) in history.indexed)
                      HmTimelineStep(
                        title: title,
                        state: state,
                        date: at == null ? (state == HmStepState.upcoming ? text.listingHistoryAfterApproval : null) : day.format(at),
                        isLast: index == history.length - 1,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (listing.editable || live)
          Container(
            padding: const EdgeInsets.all(HmSpace.xxl),
            decoration: const BoxDecoration(color: HmColors.bgPrimary, border: Border(top: BorderSide(color: HmColors.borderDefault))),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (listing.editable)
                    HmButton(
                      label: changes ? text.listingFixAndResubmit : text.listingContinueEditing,
                      icon: Icons.edit_outlined,
                      onPressed: () => context.push(Routes.partnerListingEdit(role, listing.id,
                          step: changes ? WizardStep.review.name : WizardStep.basics.name)),
                    ),
                  const SizedBox(height: HmSpace.md),
                  HmButton(label: text.listingArchive, style: HmButtonStyle.ghost, onPressed: onArchive),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
