import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_controller.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/session_store.dart';
import '../features/partner_shared/data/enquiries_repository.dart';
import '../features/partner_shared/data/listings_repository.dart';
import '../features/partner_shared/data/money_repository.dart';
import '../features/partner_shared/data/onboarding_repository.dart';
import '../features/profile/data/identity_repository.dart';
import '../features/roles/data/role_controller.dart';
import '../features/roles/data/role_preference_store.dart';
import '../features/roles/data/role_repository.dart';
import '../features/shared/activity_repository.dart';
import '../features/shared/catalogue_repository.dart';
import '../features/shared/journey_repository.dart';
import '../features/shared/models.dart';
import 'config/env.dart';
import 'contact/contact_launcher.dart';
import 'media/photo_source.dart';
import 'media/webp_encoder.dart';
import 'network/api_client.dart';

/// The composition root.
///
/// Every dependency the app has is built here and nowhere else, which is what
/// lets a test swap the whole backend for a fake with one override — and what
/// keeps widgets from reaching for an HTTP client of their own.

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SharedPreferencesSessionStore(),
);

/// Bridges the session into the transport without either knowing the other:
/// the client asks for a token, and reports a rejected one back.
class _ControllerSession implements SessionSource {
  _ControllerSession(this._ref);

  final Ref _ref;

  @override
  String? get token => _ref.read(authControllerProvider.notifier).token;

  @override
  String? get partnerRole {
    final role = _ref.read(roleControllerProvider).current;
    return (role?.isPartner ?? false) ? role!.name : null;
  }

  @override
  Future<void> onSessionRejected() =>
      _ref.read(authControllerProvider.notifier).signOut();
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(session: _ControllerSession(ref));
  ref.onDispose(client.close);
  return client;
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => HttpAuthRepository(ref.watch(apiClientProvider)),
);

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(
    repository: ref.watch(authRepositoryProvider),
    store: ref.watch(sessionStoreProvider),
  ),
);

final roleRepositoryProvider = Provider<RoleRepository>(
  (ref) => HttpRoleRepository(ref.watch(apiClientProvider)),
);

final rolePreferenceStoreProvider = Provider<RolePreferenceStore>(
  (ref) => SharedPreferencesRolePreferenceStore(),
);

/// The role in use. Loads when someone signs in (or a stored session is
/// restored) and forgets everything on sign-out — "signing out signs out of
/// every role on this phone".
final roleControllerProvider = StateNotifierProvider<RoleController, RoleState>((ref) {
  final controller = RoleController(
    repository: ref.watch(roleRepositoryProvider),
    preferences: ref.watch(rolePreferenceStoreProvider),
    auth: ref.read(authControllerProvider.notifier),
  );
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    final wasSignedIn = previous?.isSignedIn ?? false;
    final samePerson = previous?.customer?.id == next.customer?.id;
    if (next.isSignedIn && (!wasSignedIn || !samePerson)) {
      controller.load(next.customer!);
    } else if (!next.isSignedIn && wasSignedIn) {
      controller.reset();
    }
  }, fireImmediately: true);
  return controller;
});

/// The camera and gallery, behind an interface a test can replace.
final photoSourceProvider = Provider<PhotoSource>((ref) => ImagePickerPhotoSource());

final contactLauncherProvider = Provider<ContactLauncher>((ref) => UrlContactLauncher());

final webpEncoderProvider = Provider<WebpEncoder>((ref) => WebpEncoder.platformDefault());

// The partner workspaces (broker T09, landlord T10).
final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => HttpOnboardingRepository(ref.watch(apiClientProvider)),
);

final listingsRepositoryProvider = Provider<ListingsRepository>(
  (ref) => HttpListingsRepository(ref.watch(apiClientProvider)),
);

final enquiriesRepositoryProvider = Provider<EnquiriesRepository>(
  (ref) => HttpEnquiriesRepository(ref.watch(apiClientProvider)),
);

final moneyRepositoryProvider = Provider<MoneyRepository>(
  (ref) => HttpMoneyRepository(ref.watch(apiClientProvider)),
);

final catalogueRepositoryProvider = Provider<CatalogueRepository>(
  (ref) => HttpCatalogueRepository(ref.watch(apiClientProvider), baseUrl: Env.apiBaseUrl),
);

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => HttpActivityRepository(ref.watch(apiClientProvider)),
);

final identityRepositoryProvider = Provider<IdentityRepository>(
  (ref) => HttpIdentityRepository(ref.watch(apiClientProvider)),
);

/// Reserving, paying and tenancies — the half of the journey where an asking
/// becomes a commitment.
final journeyRepositoryProvider = Provider<JourneyRepository>(
  (ref) => HttpJourneyRepository(ref.watch(apiClientProvider)),
);

/// The pickers' master data. Fetched once and shared by the filter sheet, the
/// search overlay and the onboarding preferences step.
final referenceDataProvider = FutureProvider<ReferenceData>(
  (ref) => ref.watch(catalogueRepositoryProvider).reference(),
);

/// Where the customer stands with identity verification (CUS-008b).
final identityStatusProvider = FutureProvider<IdentityStatus>(
  (ref) => ref.watch(identityRepositoryProvider).identity(),
);

final customerPreferencesProvider = FutureProvider<CustomerPreferences>(
  (ref) => ref.watch(identityRepositoryProvider).preferences(),
);

/// The signed-in customer, or null. Screens watch this rather than digging
/// into the auth state themselves.
final currentCustomerProvider = Provider(
  (ref) => ref.watch(authControllerProvider).customer,
);

/// The badge counts on the home screen and the profile tab. It is a family of
/// one so that any screen can `invalidate` it after acting, and every badge in
/// the app moves together.
final activitySummaryProvider = FutureProvider<ActivitySummary>(
  (ref) => ref.watch(activityRepositoryProvider).summary(),
);
