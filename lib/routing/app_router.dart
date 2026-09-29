import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../features/auth/presentation/forgot_pin_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/pin_setup_screen.dart';
import '../features/auth/presentation/profile_setup_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/dev/widget_catalogue_screen.dart';
import '../features/broker/presentation/broker_home_screen.dart';
import '../features/broker/presentation/broker_intro_screen.dart';
import '../features/partner_shared/presentation/enquiries/partner_enquiries_screen.dart';
import '../features/partner_shared/presentation/enquiries/partner_enquiry_screen.dart';
import '../features/partner_shared/presentation/landlord_confirm_placeholder.dart';
import '../features/partner_shared/presentation/money/earning_detail_screen.dart';
import '../features/partner_shared/presentation/money/earnings_screen.dart';
import '../features/partner_shared/presentation/money/payouts_screen.dart';
import '../features/partner_shared/presentation/listings/listing_sent_screen.dart';
import '../features/partner_shared/presentation/listings/partner_listing_screen.dart';
import '../features/partner_shared/presentation/listings/partner_listings_screen.dart';
import '../features/partner_shared/presentation/listings/wizard/listing_wizard_screen.dart';
import '../features/partner_shared/presentation/listings/wizard/wizard_step.dart';
import '../features/partner_shared/presentation/setup/application_status_screen.dart';
import '../features/partner_shared/presentation/setup/partner_setup_screen.dart';
import '../features/partner_shared/presentation/setup/setup_step.dart';
import '../features/partner_shared/presentation/partner_home_placeholder.dart';
import '../features/partner_shared/presentation/partner_profile_screen.dart';
import '../features/partner_shared/presentation/partner_shell.dart';
import '../features/partner_shared/presentation/partner_tab_placeholder.dart';
import '../features/roles/data/app_role.dart';
import '../features/roles/presentation/choose_role_screen.dart';
import '../features/roles/presentation/earn_screen.dart';
import '../features/roles/presentation/role_use_screen.dart';
import '../features/discovery/presentation/home_screen.dart';
import '../features/discovery/presentation/search_overlay.dart';
import '../features/discovery/presentation/search_screen.dart';
import '../features/inquiry/presentation/inquiries_screen.dart';
import '../features/inquiry/presentation/inquiry_detail_screen.dart';
import '../features/inquiry/presentation/inquiry_form_screen.dart';
import '../features/activity/presentation/activity_screen.dart';
import '../features/activity/presentation/property_activity_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/payment/presentation/checkout_screen.dart';
import '../features/payment/presentation/payment_screen.dart';
import '../features/rental/presentation/lease_screen.dart';
import '../features/rental/presentation/rental_detail_screen.dart';
import '../features/rental/presentation/rentals_screen.dart';
import '../features/profile/presentation/identity_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/property/presentation/gallery_screen.dart';
import '../features/property/presentation/property_screen.dart';
import '../features/saved/presentation/saved_screen.dart';
import '../core/i18n/app_text.dart';
import 'app_shell.dart';
import 'deep_links.dart';
import 'role_redirect.dart';
import 'routes.dart';

export 'routes.dart';

/// Rebuilds the router's redirect whenever the session changes.
///
/// go_router needs a `Listenable`; Riverpod gives a stream. This is the one
/// adapter between them, so nothing else has to know that go_router is
/// listening at all.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) {
      if (previous?.stage != next.stage) notifyListeners();
    });
    // Loading the roles, answering AUTH-001 / ROL-001 and switching role all
    // move the person to another shell.
    ref.listen(roleControllerProvider, (previous, next) {
      // Only on a settled change, so the half-way state of a switch does not
      // send the router somewhere it immediately has to leave.
      final before = (previous?.settled ?? false, previous?.current, previous?.landing);
      final after = (next.settled, next.current, next.landing);
      if (before != after && (next.settled || (previous?.settled ?? false))) {
        notifyListeners();
      }
    });
  }
}

/// A deep link opened while signed out, kept until sign-in finishes.
final pendingDeepLinkProvider = Provider<PendingDeepLink>((_) => PendingDeepLink());

/// A partner shell: five branches in the tab order of `nav_tabs.dart`, each
/// a path and the screen at its root.
StatefulShellRoute _partnerShell(AppRole role, List<(String, Widget Function(BuildContext))> tabs) =>
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => PartnerShell(role: role, shell: shell),
      branches: [
        for (final (path, screen) in tabs)
          StatefulShellBranch(routes: [GoRoute(path: path, builder: (context, _) => screen(context))]),
      ],
    );

/// A partner's listings outside the tabs: add, open, edit and "sent".
/// `new` is listed before `:id` so it is not read as an id.
List<GoRoute> _partnerListingRoutes(AppRole role) => [
      GoRoute(path: Routes.partnerListingNew(role), builder: (_, __) => ListingWizardScreen(role: role)),
      GoRoute(
        path: '${Routes.partnerListings(role)}/:id',
        builder: (_, state) => PartnerListingScreen(role: role, listingId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) => ListingWizardScreen(
              role: role,
              listingId: state.pathParameters['id'],
              initialStep: WizardStep.fromName(state.uri.queryParameters['step']) ?? WizardStep.basics,
            ),
          ),
          GoRoute(
            path: 'sent',
            builder: (_, state) => ListingSentScreen(role: role, listingId: state.pathParameters['id']!),
          ),
        ],
      ),
    ];

/// An enquiry, an earning and the payouts, over the tabs.
List<GoRoute> _partnerWorkRoutes(AppRole role) => [
      GoRoute(
        path: Routes.partnerEnquiry(role, ':id'),
        builder: (_, state) => PartnerEnquiryScreen(role: role, enquiryId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.partnerEarning(role, ':id'),
        builder: (_, state) => EarningDetailScreen(role: role, earningId: state.pathParameters['id']!),
      ),
      GoRoute(path: Routes.partnerPayouts(role), builder: (_, __) => PayoutsScreen(role: role)),
    ];

/// The setup screens every partner role has, outside the tabs.
List<GoRoute> _partnerSetupRoutes(AppRole role) => [
      GoRoute(
        path: Routes.partnerSetup(role),
        builder: (_, state) => PartnerSetupScreen(
          role: role,
          initialStep: SetupStep.fromName(state.uri.queryParameters['step']) ?? SetupStep.details,
        ),
      ),
      GoRoute(path: Routes.partnerApplication(role), builder: (_, __) => ApplicationStatusScreen(role: role)),
    ];

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,

    /// The only place the app decides who may see what.
    ///
    /// Putting it here rather than in each screen means a new screen is
    /// guarded the moment it is added, and there is exactly one answer to
    /// "where does an unauthenticated person end up".
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final roles = ref.read(roleControllerProvider);
      final pending = ref.read(pendingDeepLinkProvider);

      // A link from outside the app (the landlord's SMS) is held through
      // sign-in and opened once the session is ready.
      final link = deepLinkLocation(state.uri);
      if (link != null && !auth.isSignedIn) pending.remember(link);
      if (link != null && auth.isSignedIn && link != state.matchedLocation) return link;
      // Kept until the router has actually arrived: a refresh can run the
      // redirect again from the old location before this one commits.
      final target = pending.location;
      if (auth.isSignedIn && roles.settled && target != null) {
        if (state.matchedLocation != target) return target;
        pending.take();
      }

      return roleRedirect(auth: auth, roles: roles, location: state.matchedLocation);
    },

    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: Routes.signIn, builder: (_, __) => const SignInScreen()),
      GoRoute(
        path: Routes.otp,
        builder: (_, state) => OtpScreen(
          phoneNumber: state.uri.queryParameters['phone'] ?? '',
          challengeId: state.uri.queryParameters['challenge'] ?? '',
          purpose: state.uri.queryParameters['purpose'] ?? 'login',
        ),
      ),
      GoRoute(
        path: Routes.pinSetup,
        builder: (_, state) => PinSetupScreen(
          verificationToken: state.uri.queryParameters['token'] ?? '',
          isReset: state.uri.queryParameters['reset'] == 'true',
        ),
      ),
      GoRoute(path: Routes.forgotPin, builder: (_, __) => const ForgotPinScreen()),
      GoRoute(path: Routes.profileSetup, builder: (_, __) => const ProfileSetupScreen()),
      if (kDebugMode) GoRoute(path: Routes.devWidgets, builder: (_, __) => const WidgetCatalogueScreen()),
      GoRoute(path: Routes.roleUse, builder: (_, __) => const RoleUseScreen()),
      GoRoute(path: Routes.chooseRole, builder: (_, __) => const ChooseRoleScreen()),
      GoRoute(path: Routes.earn, builder: (_, __) => const EarnScreen()),
      GoRoute(
        path: '${Routes.landlordConfirmPrefix}:propertyId',
        builder: (_, state) => LandlordConfirmPlaceholder(propertyId: state.pathParameters['propertyId']!),
      ),
      // The SMS link with its host already taken off by the platform.
      GoRoute(
        path: '/confirm/:propertyId',
        redirect: (_, state) => Routes.landlordConfirm(state.pathParameters['propertyId']!),
      ),
      _partnerShell(AppRole.broker, [
        (Routes.brokerHome, (_) => const BrokerHomeScreen()),
        (Routes.brokerListings, (_) => const PartnerListingsScreen(role: AppRole.broker)),
        (Routes.brokerEnquiries, (_) => const PartnerEnquiriesScreen(role: AppRole.broker)),
        (Routes.brokerEarnings, (_) => const EarningsScreen(role: AppRole.broker)),
        (Routes.brokerProfile, (_) => const PartnerProfileScreen(role: AppRole.broker)),
      ]),
      GoRoute(path: Routes.partnerIntro(AppRole.broker), builder: (_, __) => const BrokerIntroScreen()),
      ..._partnerSetupRoutes(AppRole.broker),
      ..._partnerListingRoutes(AppRole.broker),
      ..._partnerWorkRoutes(AppRole.broker),
      _partnerShell(AppRole.landlord, [
        (Routes.landlordHome, (_) => const PartnerHomePlaceholder(role: AppRole.landlord)),
        (Routes.landlordHomes, (context) => PartnerTabPlaceholder(role: AppRole.landlord, title: context.text.navHomes)),
        (Routes.landlordTenants, (context) => PartnerTabPlaceholder(role: AppRole.landlord, title: context.text.navTenants)),
        (Routes.landlordMoney, (context) => PartnerTabPlaceholder(role: AppRole.landlord, title: context.text.navMoney)),
        (Routes.landlordProfile, (_) => const PartnerProfileScreen(role: AppRole.landlord)),
      ]),
      ..._partnerSetupRoutes(AppRole.landlord),

      // The five tabs keep their own navigation stacks, so moving between them
      // does not throw away where you were.
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.home,
              builder: (_, __) => const HomeScreen(),
              routes: [
                GoRoute(path: 'notifications', builder: (_, __) => const NotificationsScreen()),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.search, builder: (_, __) => const SearchScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.saved, builder: (_, __) => const SavedScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.activity,
              builder: (_, __) => const ActivityScreen(),
              routes: [
                GoRoute(path: 'enquiries', builder: (_, __) => const InquiriesScreen()),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.profile,
              builder: (_, __) => const ProfileScreen(),
              routes: [
                GoRoute(path: 'edit', builder: (_, __) => const ProfileEditScreen()),
                GoRoute(path: 'identity', builder: (_, __) => const IdentityScreen()),
                GoRoute(path: 'preferences', builder: (_, __) => const PreferencesScreen()),
              ],
            ),
          ]),
        ],
      ),

      // Full-screen routes that cover the tabs.
      GoRoute(
        path: Routes.searchOverlay,
        builder: (_, state) => SearchOverlay(initialQuery: state.uri.queryParameters['q']),
      ),
      GoRoute(
        path: '/property/:id',
        builder: (_, state) => PropertyScreen(propertyId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'photos',
            builder: (_, state) => GalleryScreen(
              propertyId: state.pathParameters['id']!,
              initialIndex: int.tryParse(state.uri.queryParameters['start'] ?? '') ?? 0,
            ),
          ),
          GoRoute(
            path: 'enquire',
            builder: (_, state) => InquiryFormScreen(propertyId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'checkout',
            builder: (_, state) => CheckoutScreen(propertyId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'activity',
            builder: (_, state) =>
                PropertyActivityScreen(propertyId: state.pathParameters['id']!),
          ),
        ],
      ),

      // Tenancies live outside the tab shell for the same reason the other
      // detail screens do: a lease is reachable from the Favourites tab, from
      // a notification and from a payment, and nesting it inside one branch
      // means pushing it from anywhere else collides with that branch's keys.
      GoRoute(
        path: Routes.rentals,
        builder: (_, __) => const RentalsScreen(),
        routes: [
          GoRoute(
            path: ':bookingId',
            builder: (_, state) =>
                RentalDetailScreen(bookingId: state.pathParameters['bookingId']!),
            routes: [
              GoRoute(
                path: 'lease',
                builder: (_, state) => LeaseScreen(bookingId: state.pathParameters['bookingId']!),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/enquiry/:id',
        builder: (_, state) => InquiryDetailScreen(inquiryId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/payment/:id',
        builder: (_, state) => PaymentScreen(paymentId: state.pathParameters['id']!),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.explore_off_outlined, size: 44),
              const SizedBox(height: 16),
              const Text('That page does not exist.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(Routes.home),
                child: const Text('Go home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});
