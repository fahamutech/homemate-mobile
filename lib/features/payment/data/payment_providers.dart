import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../shared/models.dart';

final paymentProvider = FutureProvider.family<CustomerPayment, String>((ref, id) {
  return ref.watch(activityRepositoryProvider).payment(id);
});
