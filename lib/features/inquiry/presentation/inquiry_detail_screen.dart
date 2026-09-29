import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_prompt.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../design/widgets/hm_section.dart';
import '../../../design/widgets/hm_status_chip.dart';
import '../../../design/widgets/hm_timeline.dart';
import '../../../routing/app_router.dart';
import '../../shared/journey_models.dart';
import '../../shared/journey_providers.dart';
import '../../shared/models.dart';
import '../../shared/property_image.dart';
import '../data/inquiry_providers.dart';
import '../../../core/i18n/app_text.dart';
import '../../payment/presentation/checkout_labels.dart';

/// CUS-007d/e/f. One enquiry: where it has got to, and what to do next.
///
/// The screen is built around the status timeline rather than a chat log,
/// because the customer's question is almost never "what did I write" — it is
/// "is anything happening". So the timeline comes first, and what follows it
/// depends on which of the three states the enquiry is in:
///
///   - **pending / responded** — a nudge, so a customer who has been waiting
///     three days has something to do other than wait;
///   - **accepted** — the payment button, because an approval that does not
///     lead anywhere is where this flow used to end;
///   - **rejected** — the reason, and a way back to looking.
class InquiryDetailScreen extends ConsumerWidget {
  const InquiryDetailScreen({super.key, required this.inquiryId});

  final String inquiryId;

  void _invalidate(WidgetRef ref) {
    ref.invalidate(inquiryProvider(inquiryId));
    ref.invalidate(inquiryJourneyProvider(inquiryId));
    ref.invalidate(inquiriesProvider(null));
    ref.invalidate(activitySummaryProvider);
    ref.invalidate(savedOverviewProvider);
  }

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final confirmed = await HmConfirm.show(
      context,
      title: context.text.inquiryDetailWithdrawQ,
      message: context.text.inquiryDetailWithdrawBody,
      cancelLabel: context.text.inquiryDetailKeep,
      confirmLabel: context.text.inquiryDetailWithdraw,
      destructive: true,
    );
    if (!confirmed) return;

    try {
      await ref.read(activityRepositoryProvider).withdrawInquiry(inquiryId);
      _invalidate(ref);
      if (context.mounted) HmFeedback.success(context, context.text.inquiryDetailWithdrawn);
    } catch (error) {
      if (context.mounted) HmFeedback.failure(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inquiry = ref.watch(inquiryProvider(inquiryId));
    final journey = ref.watch(inquiryJourneyProvider(inquiryId));

    return HmScaffold(
      title: context.text.inquiryDetailTitle,
      padded: false,
      backgroundColor: HmColors.bgSecondary,
      body: RefreshIndicator(
        onRefresh: () async => _invalidate(ref),
        child: HmAsync(
          value: inquiry,
          onRetry: () => _invalidate(ref),
          data: (data) => ListView(
            padding: const EdgeInsets.fromLTRB(
              HmSpace.xxl,
              HmSpace.xxl,
              HmSpace.xxl,
              HmSpace.section,
            ),
            children: [
              if (data.propertyId != null) _PropertyCard(inquiry: data),
              const SizedBox(height: HmSpace.huge),

              HmSectionHeader(title: context.text.inquiryDetailTimeline),
              HmAsync(
                value: journey,
                onRetry: () => ref.invalidate(inquiryJourneyProvider(inquiryId)),
                loading: const Padding(
                  padding: EdgeInsets.symmetric(vertical: HmSpace.huge),
                  child: HmLoading(),
                ),
                emptyWhen: (events) => events.isEmpty,
                empty: const SizedBox.shrink(),
                data: (events) => HmCard(child: HmTimeline(events: events)),
              ),
              const SizedBox(height: HmSpace.huge),

              if (data.message.isNotEmpty)
                HmCard(
                  title: context.text.inquiryDetailAsked,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.message, style: HmText.body),
                      const SizedBox(height: HmSpace.xl),
                      Text(
                        DateFormat('d MMM yyyy, h:mm a').format(data.createdAt),
                        style: HmText.caption,
                      ),
                    ],
                  ),
                ),

              if (data.wasAnswered) ...[
                const SizedBox(height: HmSpace.xl),
                HmCard(
                  title: context.text.inquiryDetailReplied,
                  child: Text(data.response!, style: HmText.body),
                ),
              ],

              const SizedBox(height: HmSpace.huge),
              _NextStep(inquiry: data, onChanged: () => _invalidate(ref)),

              if (data.isOpen) ...[
                const SizedBox(height: HmSpace.huge),
                OutlinedButton(
                  onPressed: () => _withdraw(context, ref),
                  style: OutlinedButton.styleFrom(foregroundColor: HmColors.error),
                  child: Text(context.text.inquiryDetailWithdrawEnquiry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.inquiry});

  final Inquiry inquiry;

  @override
  Widget build(BuildContext context) => Material(
        color: HmColors.bgPrimary,
        borderRadius: HmRadius.card,
        child: InkWell(
          onTap: () => context.push(Routes.property(inquiry.propertyId!)),
          borderRadius: HmRadius.card,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: HmRadius.card,
              border: Border.all(color: HmColors.borderDefault),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PropertyImage(
                  mediaId: inquiry.coverMediaId,
                  height: 160,
                  borderRadius: BorderRadius.zero,
                ),
                Padding(
                  padding: const EdgeInsets.all(HmSpace.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              inquiry.propertyTitle ?? context.text.leaseProperty,
                              style: HmText.heading,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: HmSpace.md),
                          HmStatusChip(
                            // The server's reading of the whole journey: an
                            // accepted enquiry is "awaiting payment", then
                            // "awaiting verification", then "paid" — so this
                            // chip and the timeline give one answer.
                            inquiry.displayStatus,
                            dense: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: HmSpace.sm),
                      Text(inquiry.reference, style: HmText.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// What the customer should do now. Exactly one of these is ever on screen.
class _NextStep extends ConsumerStatefulWidget {
  const _NextStep({required this.inquiry, required this.onChanged});

  final Inquiry inquiry;
  final VoidCallback onChanged;

  @override
  ConsumerState<_NextStep> createState() => _NextStepState();
}

class _NextStepState extends ConsumerState<_NextStep> {
  bool _busy = false;

  Future<void> _nudge() async {
    setState(() => _busy = true);
    try {
      await ref.read(journeyRepositoryProvider).nudgeInquiry(widget.inquiry.id);
      widget.onChanged();
      if (mounted) {
        HmFeedback.success(context, context.text.inquiryDetailReminderSent);
      }
    } catch (error) {
      // The cooldown arrives as an ordinary failure and reads as one: it
      // already says when another reminder may be sent.
      if (mounted) HmFeedback.failure(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inquiry = widget.inquiry;
    final propertyId = inquiry.propertyId;

    if (inquiry.status == 'rejected') {
      return Column(
        children: [
          HmNotice(
            message: inquiry.rejectionReason?.isNotEmpty == true
                ? context.text.inquiryDetailDeclinedWhy(inquiry.rejectionReason!)
                : context.text.inquiryDetailDeclined,
            icon: Icons.cancel_outlined,
            colour: HmColors.error,
          ),
          const SizedBox(height: HmSpace.huge),
          OutlinedButton(
            onPressed: () => context.go(Routes.search),
            child: Text(context.text.inquiryDetailFindAnother),
          ),
        ],
      );
    }

    // Paid and verified: the journey is over and the home is theirs.
    if (inquiry.isPaid) {
      return Column(
        children: [
          HmNotice(
            message: context.text.inquiryDetailVerified,
            icon: Icons.check_circle_outline,
            colour: HmColors.success,
          ),
          if (inquiry.bookingId case final bookingId?) ...[
            const SizedBox(height: HmSpace.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(Routes.rental(bookingId)),
                icon: const Icon(Icons.vpn_key_outlined, size: 18),
                label: Text(context.text.inquiryDetailViewRental),
              ),
            ),
          ],
        ],
      );
    }

    // Paid, and a person is checking the money arrived.
    if (inquiry.isBeingVerified) {
      return HmNotice(
        message: context.text.inquiryDetailVerifying,
        icon: Icons.hourglass_top_outlined,
        colour: HmColors.info,
      );
    }

    if (inquiry.status == 'accepted' && propertyId != null) {
      return _PayNow(inquiry: inquiry, propertyId: propertyId);
    }

    if (inquiry.isOpen) {
      final waitingDays = DateTime.now().difference(inquiry.createdAt).inDays;

      return Column(
        children: [
          HmNotice(
            message: waitingDays >= 2
                ? context.text.inquiryDetailWaiting(waitingDays)
                : context.text.inquiryDetailWithLandlord,
            icon: Icons.schedule_outlined,
            colour: HmColors.warning,
          ),
          const SizedBox(height: HmSpace.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _nudge,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: HmColors.textOnBrand),
                    )
                  : const Icon(Icons.notifications_active_outlined, size: 18),
              label: Text(context.text.inquiryDetailNudge),
            ),
          ),
          const SizedBox(height: HmSpace.md),
          Text(
            context.text.inquiryDetailOneADay,
            style: HmText.caption.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

/// The accepted state. The point of the whole enquiry flow, and the thing that
/// used to be missing: an approval that leads straight to paying for it.
class _PayNow extends ConsumerWidget {
  const _PayNow({required this.inquiry, required this.propertyId});

  final Inquiry inquiry;
  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligibility = ref.watch(checkoutEligibilityProvider(propertyId));

    return eligibility.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: HmSpace.huge),
        child: HmLoading(),
      ),
      // A failed eligibility check must not hide the button — the checkout
      // asks the same question again and refuses properly if it has to.
      error: (_, __) => _button(context, null),
      data: (data) => Column(
        children: [
          HmNotice(
            message: checkoutReason(context.text, data.route),
            icon: Icons.verified_outlined,
            colour: HmColors.brandPrimary,
          ),
          if (data.isBlockedByHold) ...[
            const SizedBox(height: HmSpace.xl),
            HmNotice(
              message: context.text.inquiryDetailSomeonePaying,
              icon: Icons.hourglass_top_outlined,
            ),
          ],
          const SizedBox(height: HmSpace.xl),
          _button(context, data),
        ],
      ),
    );
  }

  Widget _button(BuildContext context, CheckoutEligibility? eligibility) {
    final blocked = eligibility?.isBlockedByHold ?? false;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: blocked ? null : () => context.push(Routes.checkout(propertyId)),
        icon: const Icon(Icons.lock_outline, size: 18),
        label: Text(
          // The amount when the server has told us one, and a plain verb when
          // it has not — a button that says "Pay TZS 0" is worse than one that
          // just says "Pay".
          eligibility?.hasStarted ?? false ? context.text.propertyContinuePayment : context.text.inquiryDetailPayNow,
        ),
      ),
    );
  }
}
