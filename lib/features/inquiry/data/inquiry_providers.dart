import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../shared/models.dart';

final inquiriesProvider = FutureProvider.family<Paged<Inquiry>, String?>((ref, status) {
  return ref.watch(activityRepositoryProvider).inquiries(status: status, limit: 50);
});

final inquiryProvider = FutureProvider.family<Inquiry, String>((ref, id) {
  return ref.watch(activityRepositoryProvider).inquiry(id);
});
