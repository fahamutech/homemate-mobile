import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_prompt.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../design/widgets/hm_status_chip.dart';
import '../../../routing/app_router.dart';
import '../../shared/property_image.dart';
import '../data/inquiry_providers.dart';

/// CUS-007b/d/e/f. One enquiry: what was asked, what came back, what to do
/// next.
class InquiryDetailScreen extends ConsumerWidget {
  const InquiryDetailScreen({super.key, required this.inquiryId});

  final String inquiryId;

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final confirmed = await HmConfirm.show(
      context,
      title: 'Withdraw this enquiry?',
      message: 'The landlord will no longer see it. You can always ask again later.',
      cancelLabel: 'Keep it',
      confirmLabel: 'Withdraw',
      destructive: true,
    );
    if (!confirmed) return;

    try {
      await ref.read(activityRepositoryProvider).withdrawInquiry(inquiryId);
      ref.invalidate(inquiryProvider(inquiryId));
      ref.invalidate(inquiriesProvider(null));
      ref.invalidate(activitySummaryProvider);
      if (context.mounted) HmFeedback.success(context, 'Enquiry withdrawn');
    } catch (error) {
      if (context.mounted) HmFeedback.failure(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inquiry = ref.watch(inquiryProvider(inquiryId));

    return HmScaffold(
      title: 'Enquiry',
      body: HmAsync(
        value: inquiry,
        onRetry: () => ref.invalidate(inquiryProvider(inquiryId)),
        data: (data) => ListView(
          children: [
            Row(
              children: [
                Expanded(child: HmStatusChip(data.status)),
                Text(data.reference, style: HmText.caption),
              ],
            ),
            const SizedBox(height: HmSpace.huge),

            if (data.propertyId != null)
              Card(
                child: InkWell(
                  borderRadius: HmRadius.card,
                  onTap: () => context.push(Routes.property(data.propertyId!)),
                  child: Padding(
                    padding: const EdgeInsets.all(HmSpace.xxl),
                    child: Row(
                      children: [
                        PropertyImage(mediaId: data.coverMediaId, height: 56, width: 56),
                        const SizedBox(width: HmSpace.xxl),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data.propertyTitle ?? 'Property', style: HmText.label),
                              Text(data.propertyReference ?? '', style: HmText.caption),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: HmColors.textDisabled),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: HmSpace.huge),
            _Bubble(
              title: 'You asked',
              body: data.message,
              timestamp: data.createdAt,
              mine: true,
            ),

            if (data.wasAnswered)
              _Bubble(
                title: 'Reply',
                body: data.response!,
                timestamp: data.respondedAt,
                mine: false,
              ),

            if (data.status == 'rejected' && data.rejectionReason != null)
              _Bubble(
                title: 'Declined',
                body: data.rejectionReason!,
                timestamp: data.respondedAt,
                mine: false,
                accent: HmColors.error,
              ),

            if (data.status == 'pending')
              const Padding(
                padding: EdgeInsets.only(top: HmSpace.huge),
                child: Text(
                  'Waiting for a reply. Most landlords answer within a day.',
                  style: HmText.caption,
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: HmSpace.section),

            if (data.propertyId != null && data.status != 'rejected') ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.event_available_outlined, size: 18),
                label: const Text('Book a viewing'),
                onPressed: () => context.push(Routes.scheduleViewing(data.propertyId!)),
              ),
              const SizedBox(height: HmSpace.xl),
            ],

            if (data.isOpen)
              OutlinedButton(
                onPressed: () => _withdraw(context, ref),
                style: OutlinedButton.styleFrom(foregroundColor: HmColors.error),
                child: const Text('Withdraw enquiry'),
              ),
          ],
        ),
      ),
    );
  }
}

/// One side of the conversation. Reads as a thread rather than a form, because
/// that is what an enquiry is.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.title,
    required this.body,
    required this.mine,
    this.timestamp,
    this.accent,
  });

  final String title;
  final String body;
  final bool mine;
  final DateTime? timestamp;
  final Color? accent;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: HmSpace.xl),
        padding: const EdgeInsets.all(HmSpace.xxl),
        decoration: BoxDecoration(
          color: mine ? HmColors.surfaceInput : (accent ?? HmColors.brandPrimary).withValues(alpha: 0.08),
          borderRadius: HmRadius.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: HmText.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: mine ? HmColors.textSecondary : (accent ?? HmColors.brandPrimary),
              ),
            ),
            const SizedBox(height: HmSpace.sm),
            Text(body, style: HmText.body),
            if (timestamp != null) ...[
              const SizedBox(height: HmSpace.md),
              Text(
                '${timestamp!.day}/${timestamp!.month}/${timestamp!.year}',
                style: HmText.caption,
              ),
            ],
          ],
        ),
      );
}
