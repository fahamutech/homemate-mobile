import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../design/widgets/hm_status_chip.dart';
import '../../../routing/app_router.dart';
import '../../shared/models.dart';
import '../../shared/property_image.dart';
import '../data/inquiry_providers.dart';
import '../../../core/i18n/app_text.dart';

/// CUS-007c. Every enquiry the customer has sent.
class InquiriesScreen extends ConsumerWidget {
  const InquiriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inquiries = ref.watch(inquiriesProvider(null));

    return HmScaffold(
      title: context.text.inquiriesTitle,
      padded: false,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(inquiriesProvider(null)),
        child: HmAsync(
          value: inquiries,
          onRetry: () => ref.invalidate(inquiriesProvider(null)),
          emptyWhen: (page) => page.isEmpty,
          empty: HmEmpty(
            title: context.text.enquiriesNone,
            message: context.text.inquiriesEmptyBody,
            icon: Icons.question_answer_outlined,
            action: OutlinedButton(
              onPressed: () => context.go(Routes.search),
              child: Text(context.text.rentalsFind),
            ),
          ),
          data: (page) => ListView.separated(
            padding: const EdgeInsets.all(HmSpace.xxl),
            itemCount: page.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: HmSpace.xl),
            itemBuilder: (_, index) => InquiryTile(inquiry: page.items[index]),
          ),
        ),
      ),
    );
  }
}

/// One enquiry in a list. Shared by the enquiries screen and the activity
/// timeline, so a status reads the same in both.
class InquiryTile extends StatelessWidget {
  const InquiryTile({super.key, required this.inquiry});

  final Inquiry inquiry;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: HmRadius.card,
          onTap: () => context.push(Routes.inquiry(inquiry.id)),
          child: Padding(
            padding: const EdgeInsets.all(HmSpace.xxl),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PropertyImage(mediaId: inquiry.coverMediaId, height: 64, width: 64),
                const SizedBox(width: HmSpace.xxl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inquiry.propertyTitle ?? context.text.leaseProperty,
                        style: HmText.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: HmSpace.xs),
                      Text(
                        // The reply matters more than what was asked, once
                        // there is one.
                        inquiry.wasAnswered ? inquiry.response! : inquiry.message,
                        style: HmText.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: HmSpace.md),
                      Row(
                        children: [
                          HmStatusChip(inquiry.displayStatus, dense: true),
                          const SizedBox(width: HmSpace.md),
                          Text(inquiry.reference, style: HmText.caption),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
