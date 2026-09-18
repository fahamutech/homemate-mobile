import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../shared/models.dart';

final viewingsProvider = FutureProvider.family<Paged<Viewing>, bool>((ref, upcomingOnly) {
  return ref.watch(activityRepositoryProvider).viewings(upcomingOnly: upcomingOnly, limit: 50);
});

final viewingProvider = FutureProvider.family<Viewing, String>((ref, id) {
  return ref.watch(activityRepositoryProvider).viewing(id);
});
