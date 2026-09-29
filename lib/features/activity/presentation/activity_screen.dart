import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../routing/app_router.dart';
import '../../inquiry/data/inquiry_providers.dart';
import '../../inquiry/presentation/inquiries_screen.dart';
import '../../../core/i18n/app_text.dart';

/// CUS-016. The Activity tab.
///
/// The journey to a home is one road now — enquire, be accepted, pay, have the
/// payment verified — and every step of it hangs off the enquiry. So this tab
/// is the customer's enquiries, each showing where it has got to (with the
/// landlord, awaiting payment, being verified, paid), with the tenancies they
/// turned into one tap away.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inquiries = ref.watch(inquiriesProvider(null));

    return Scaffold(
      appBar: AppBar(title: Text(context.text.activityTitle)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(inquiriesProvider(null)),
        child: ListView(
          padding: const EdgeInsets.all(HmSpace.xxl),
          children: [
            _Shortcut(
              icon: Icons.vpn_key_outlined,
              label: context.text.rentalsTitle,
              caption: context.text.activityRentalsCaption,
              onTap: () => context.push(Routes.rentals),
            ),
            const SizedBox(height: HmSpace.huge),
            Text(context.text.activityYourEnquiries, style: HmText.heading),
            const SizedBox(height: HmSpace.xs),
            Text(
              context.text.activityHowItWorks,
              style: HmText.caption,
            ),
            const SizedBox(height: HmSpace.xl),
            HmAsync(
              value: inquiries,
              onRetry: () => ref.invalidate(inquiriesProvider(null)),
              emptyWhen: (page) => page.isEmpty,
              loading: const Padding(
                padding: EdgeInsets.symmetric(vertical: HmSpace.section),
                child: HmLoading(),
              ),
              empty: HmEmpty(
                title: context.text.enquiriesNone,
                message: context.text.activityEmptyBody,
                icon: Icons.question_answer_outlined,
                action: OutlinedButton(
                  onPressed: () => context.go(Routes.search),
                  child: Text(context.text.rentalsFind),
                ),
              ),
              data: (page) => Column(
                children: [
                  for (final inquiry in page.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: HmSpace.xl),
                      child: InquiryTile(inquiry: inquiry),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.icon, required this.label, required this.caption, required this.onTap});

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: HmRadius.card,
        child: Container(
          padding: const EdgeInsets.all(HmSpace.xxl),
          decoration: BoxDecoration(
            color: HmColors.surfaceInput,
            borderRadius: HmRadius.card,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: HmColors.brandPrimary),
              const SizedBox(width: HmSpace.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: HmText.label),
                    const SizedBox(height: HmSpace.xxs),
                    Text(caption, style: HmText.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: HmColors.textDisabled),
            ],
          ),
        ),
      );
}
