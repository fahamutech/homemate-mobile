import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/providers.dart';
import 'package:homemate_mobile/features/auth/data/customer.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_listing.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/listings/partner_listing_screen.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/listings/wizard/listing_wizard_screen.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';
import 'package:homemate_mobile/routing/app_router.dart';

import '../support/fakes.dart';

/// The broker's paths resolve to the right screens on the real router.
void main() {
  testWidgets('/broker/listings/new is the wizard, /broker/listings/:id the listing', (tester) async {
    final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.broker));
    await harness.rolePreferences.setAlwaysOpenAs('cust-1', AppRole.broker);
    harness.listings.seed(const PartnerListing(id: 'p1', status: 'draft', title: 'Masaki'));
    final container = ProviderContainer(overrides: harness.overrides);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).adopt(AuthSessionStub(
          token: 'session-token',
          customer: const Customer(id: 'cust-1', phoneNumber: '+255712345678', fullName: 'Baraka', hasPin: true, onboardingComplete: true),
        ));
    final router = container.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: testApp(router)));
    await tester.pumpAndSettle();

    router.go(Routes.partnerListingNew(AppRole.broker));
    await tester.pumpAndSettle();
    expect(find.byType(ListingWizardScreen), findsOneWidget);

    router.go(Routes.partnerListing(AppRole.broker, 'p1'));
    await tester.pumpAndSettle();
    expect(find.byType(PartnerListingScreen), findsOneWidget);

    router.go(Routes.partnerListingEdit(AppRole.broker, 'p1', step: 'photos'));
    await tester.pumpAndSettle();
    expect(find.text('STEP 6 OF 6 · PHOTOS'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  });
}
