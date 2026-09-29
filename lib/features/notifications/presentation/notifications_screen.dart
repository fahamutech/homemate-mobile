import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../routing/app_router.dart';
import '../../shared/models.dart';
import '../data/notification_providers.dart';
import '../../../core/i18n/app_text.dart';

/// CUS-020. What happened while the customer was away.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  /// Tapping a notification should land on the thing it is about, not on a
  /// dead end that says "your booking was updated".
  static String? _destinationFor(AppNotification notification) {
    final id = notification.subjectId;
    if (id == null) return null;
    return switch (notification.subjectTable) {
      'property_inquiries' => Routes.inquiry(id),
      // A reservation whose payment was verified is a tenancy: the rental is
      // what the customer wants to see.
      'bookings' => Routes.rental(id),
      'payments' => Routes.payment(id),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return HmScaffold(
      title: context.text.notifications,
      padded: false,
      actions: [
        TextButton(
          onPressed: () async {
            try {
              await ref.read(activityRepositoryProvider).markAllNotificationsRead();
              ref.invalidate(notificationsProvider);
              ref.invalidate(activitySummaryProvider);
            } catch (error) {
              if (context.mounted) HmFeedback.failure(context, error);
            }
          },
          child: Text(context.text.notificationsMarkAll),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(notificationsProvider),
        child: HmAsync(
          value: notifications,
          onRetry: () => ref.invalidate(notificationsProvider),
          emptyWhen: (page) => page.isEmpty,
          empty: HmEmpty(
            title: context.text.notificationsEmpty,
            message: context.text.notificationsEmptyBody,
            icon: Icons.notifications_none_rounded,
          ),
          data: (page) => ListView.separated(
            itemCount: page.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final notification = page.items[index];
              final destination = _destinationFor(notification);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: notification.isUnread
                      ? HmColors.brandPrimarySoft
                      : HmColors.surfaceInput,
                  child: Icon(
                    _iconFor(notification.kind),
                    size: 18,
                    color: notification.isUnread ? HmColors.brandPrimary : HmColors.textDisabled,
                  ),
                ),
                title: Text(
                  notification.title,
                  style: HmText.label.copyWith(
                    fontWeight: notification.isUnread ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                subtitle: notification.body == null ? null : Text(notification.body!),
                trailing: notification.isUnread
                    ? const Icon(Icons.circle, size: 8, color: HmColors.brandPrimary)
                    : null,
                onTap: () async {
                  if (notification.isUnread) {
                    // Fire and forget: failing to mark it read must not block
                    // opening what it points at.
                    ref
                        .read(activityRepositoryProvider)
                        .markNotificationRead(notification.id)
                        .then((_) {
                      ref.invalidate(notificationsProvider);
                      ref.invalidate(activitySummaryProvider);
                    }).catchError((_) {});
                  }
                  if (destination != null && context.mounted) context.push(destination);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(String kind) => switch (kind) {
        'inquiry_response' => Icons.question_answer_outlined,
        'booking_update' => Icons.receipt_long_outlined,
        'payment_due' => Icons.account_balance_wallet_outlined,
        'payment_received' => Icons.check_circle_outline,
        'kyc_update' => Icons.badge_outlined,
        _ => Icons.info_outline,
      };
}
