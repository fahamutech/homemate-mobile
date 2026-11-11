import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../routing/app_router.dart';
import '../../roles/data/app_role.dart';
import '../../shared/models.dart';
import '../data/notification_providers.dart';
import '../../../core/i18n/app_text.dart';

/// Tapping a notification should land on the thing it is about, not on a
/// dead end that says "your booking was updated". The same enquiry is the
/// customer's own enquiry screen to a customer and the partner's enquiry screen
/// to its broker, so the answer depends on the inbox it is read in.
String? notificationDestination(AppNotification notification, AppRole role) {
  final id = notification.subjectId;
  if (id == null) return null;

  if (role == AppRole.customer) {
    return switch (notification.subjectTable) {
      'property_inquiries' => Routes.inquiry(id),
      // A reservation whose payment was verified is a tenancy: the rental is
      // what the customer wants to see.
      'bookings' => Routes.rental(id),
      'payments' => Routes.payment(id),
      'users' => Routes.identity,
      _ => null,
    };
  }

  return switch (notification.subjectTable) {
    'property_inquiries' => Routes.partnerEnquiry(role, id),
    'payment_splits' => Routes.partnerEarning(role, id),
    'payouts' => Routes.partnerPayouts(role),
    // A broker listing a landlord's home asks the landlord to confirm it;
    // every other listing notice is about a listing the partner made.
    'properties' when role == AppRole.landlord && notification.kind == 'system' => Routes.landlordConfirm(id),
    'properties' => Routes.partnerListing(role, id),
    'bookings' when role == AppRole.landlord => Routes.landlordTenancy(id),
    'user_roles' => Routes.partnerApplication(role),
    'users' => Routes.partnerProfile(role),
    _ => null,
  };
}

/// CUS-020. What happened while the customer was away — or, opened from a
/// partner home, what happened on the broker's or landlord's side.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key, this.role = AppRole.customer});

  final AppRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audience = role.name;
    final notifications = ref.watch(notificationsProvider(audience));

    void refreshCounts() {
      ref.invalidate(notificationsProvider(audience));
      ref.invalidate(unreadNotificationsProvider(audience));
      ref.invalidate(activitySummaryProvider);
    }

    return HmScaffold(
      title: context.text.notifications,
      padded: false,
      actions: [
        TextButton(
          onPressed: () async {
            try {
              await ref.read(activityRepositoryProvider).markAllNotificationsRead(audience: audience);
              refreshCounts();
            } catch (error) {
              if (context.mounted) HmFeedback.failure(context, error);
            }
          },
          child: Text(context.text.notificationsMarkAll),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async => refreshCounts(),
        child: HmAsync(
          value: notifications,
          onRetry: () => ref.invalidate(notificationsProvider(audience)),
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
              final destination = notificationDestination(notification, role);

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
                        .then((_) => refreshCounts())
                        .catchError((_) {});
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
        'enquiry_received' => Icons.mark_email_unread_outlined,
        'listing_update' => Icons.home_work_outlined,
        'payout_update' => Icons.payments_outlined,
        'booking_update' => Icons.receipt_long_outlined,
        'payment_due' => Icons.account_balance_wallet_outlined,
        'payment_received' => Icons.check_circle_outline,
        'kyc_update' => Icons.badge_outlined,
        _ => Icons.info_outline,
      };
}
