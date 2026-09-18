import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../shared/models.dart';

final bookingsProvider = FutureProvider.family<Paged<Booking>, String?>((ref, status) {
  return ref.watch(activityRepositoryProvider).bookings(status: status, limit: 50);
});

final bookingProvider = FutureProvider.family<Booking, String>((ref, id) {
  return ref.watch(activityRepositoryProvider).booking(id);
});

final paymentProvider = FutureProvider.family<CustomerPayment, String>((ref, id) {
  return ref.watch(activityRepositoryProvider).payment(id);
});
