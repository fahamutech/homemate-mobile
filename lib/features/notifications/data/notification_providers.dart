import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../shared/models.dart';

/// One role's inbox, keyed by audience (`customer`, `broker`, `landlord`).
/// The server adds the notices about the account itself to each.
final notificationsProvider = FutureProvider.family<Paged<AppNotification>, String>((ref, audience) {
  return ref.watch(activityRepositoryProvider).notifications(audience: audience, limit: 50);
});

/// The partner bell's badge. The customer home reads its count from the
/// activity summary, which the server scopes to the customer inbox.
final unreadNotificationsProvider = FutureProvider.family<int, String>((ref, audience) {
  return ref.watch(activityRepositoryProvider).unreadNotificationCount(audience: audience);
});
