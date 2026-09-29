import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import 'listing_confirmation.dart';
import 'tenancy.dart';

final listingConfirmationsProvider = FutureProvider.autoDispose<List<ListingConfirmation>>(
  (ref) => ref.watch(confirmationsRepositoryProvider).list(),
);

final tenanciesProvider = FutureProvider.autoDispose.family<List<Tenancy>, TenancyStage?>(
  (ref, stage) => ref.watch(tenanciesRepositoryProvider).list(stage: stage),
);

final tenancyProvider = FutureProvider.autoDispose.family<Tenancy, String>(
  (ref, id) => ref.watch(tenanciesRepositoryProvider).get(id),
);
