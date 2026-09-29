import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../roles/data/app_role.dart';
import 'partner_application.dart';
import 'partner_enquiry.dart';
import 'partner_listing.dart';
import 'partner_money.dart';

/// Reads for the partner screens, one provider per thing shown. After an
/// action a screen invalidates what it changed; nothing caches by hand.

/// The role whose shell is on screen, as the API names it.
final partnerRoleProvider = Provider<String>((ref) {
  final role = ref.watch(roleControllerProvider).current;
  return (role?.isPartner ?? false) ? role!.name : AppRole.broker.name;
});

final applicationsProvider = FutureProvider.autoDispose<ApplicationsOverview>(
  (ref) => ref.watch(onboardingRepositoryProvider).overview(),
);

/// The application of the role on screen.
final currentApplicationProvider = FutureProvider.autoDispose<PartnerApplication>((ref) async {
  final overview = await ref.watch(applicationsProvider.future);
  return overview.application(ref.watch(partnerRoleProvider));
});

final partnerListingsProvider = FutureProvider.autoDispose.family<List<PartnerListingSummary>, String?>(
  (ref, status) => ref.watch(listingsRepositoryProvider).list(status: status),
);

final partnerListingProvider = FutureProvider.autoDispose.family<PartnerListing, String>(
  (ref, id) => ref.watch(listingsRepositoryProvider).get(id),
);

final partnerEnquiriesProvider = FutureProvider.autoDispose.family<List<PartnerEnquiry>, String?>(
  (ref, tab) => ref.watch(enquiriesRepositoryProvider).list(tab: tab),
);

final partnerEnquiryProvider = FutureProvider.autoDispose.family<PartnerEnquiry, String>(
  (ref, id) => ref.watch(enquiriesRepositoryProvider).get(id),
);

final enquiryJourneyProvider = FutureProvider.autoDispose.family<EnquiryJourney, String>(
  (ref, id) => ref.watch(enquiriesRepositoryProvider).journey(id),
);

final earningsProvider = FutureProvider.autoDispose<EarningsOverview>(
  (ref) => ref.watch(moneyRepositoryProvider).earnings(ref.watch(partnerRoleProvider)),
);

final earningProvider = FutureProvider.autoDispose.family<EarningDetail, String>(
  (ref, id) => ref.watch(moneyRepositoryProvider).earning(id),
);

final payoutsProvider = FutureProvider.autoDispose<PayoutsOverview>(
  (ref) => ref.watch(moneyRepositoryProvider).payouts(ref.watch(partnerRoleProvider)),
);

/// The home summary. Only an active role has one; before that the home shows
/// the setup checklist instead.
final partnerSummaryProvider = FutureProvider.autoDispose<PartnerSummary>(
  (ref) => ref.watch(moneyRepositoryProvider).summary(ref.watch(partnerRoleProvider)),
);
