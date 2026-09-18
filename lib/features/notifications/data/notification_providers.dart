import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../shared/models.dart';

final notificationsProvider = FutureProvider<Paged<AppNotification>>((ref) {
  return ref.watch(activityRepositoryProvider).notifications(limit: 50);
});
