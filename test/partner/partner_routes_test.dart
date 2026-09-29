import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/providers.dart';
import 'package:homemate_mobile/features/auth/data/customer.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_listing.dart';
import 'package:homemate_mobile/features/landlord/data/tenancy.dart';
import 'package:homemate_mobile/features/landlord/presentation/confirm/confirm_listing_screen.dart';
import 'package:homemate_mobile/features/landlord/presentation/landlord_intro_screen.dart';
import 'package:homemate_mobile/features/landlord/presentation/tenants/tenancy_screen.dart';
import 'package:homemate_mobile/features/landlord/presentation/tenants/tenants_screen.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_enquiry.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_money.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/enquiries/partner_enquiries_screen.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/enquiries/partner_enquiry_screen.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/listings/partner_listing_screen.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/listings/partner_listings_screen.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/money/earning_detail_screen.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/money/earnings_screen.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/money/payouts_screen.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/listings/wizard/listing_wizard_screen.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';
import 'package:homemate_mobile/routing/app_router.dart';

import '../support/fakes.dart';

/// The broker's paths resolve to the right screens on the real router.
void main() {
  testWidgets('every broker path opens its screen', (tester) async {
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

    harness.enquiries.enquiries['i1'] = const PartnerEnquiry(id: 'i1', status: 'pending', customerName: 'Amina Juma', canAnswer: true);
    router.go(Routes.partnerEnquiry(AppRole.broker, 'i1'));
    await tester.pumpAndSettle();
    expect(find.byType(PartnerEnquiryScreen), findsOneWidget);

    router.go(Routes.brokerEnquiries);
    await tester.pumpAndSettle();
    expect(find.byType(PartnerEnquiriesScreen), findsOneWidget);

    router.go(Routes.brokerEarnings);
    await tester.pumpAndSettle();
    expect(find.byType(EarningsScreen), findsOneWidget);

    router.go(Routes.partnerPayouts(AppRole.broker));
    await tester.pumpAndSettle();
    expect(find.byType(PayoutsScreen), findsOneWidget);

    harness.money.details['e1'] = const EarningDetail(earning: Earning(id: 'e1', amount: 1, state: 'ready'));
    router.go(Routes.partnerEarning(AppRole.broker, 'e1'));
    await tester.pumpAndSettle();
    expect(find.byType(EarningDetailScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  });

  testWidgets('every landlord path opens its screen', (tester) async {
    final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.landlord));
    await harness.rolePreferences.setAlwaysOpenAs('cust-1', AppRole.landlord);
    harness.listings.seed(const PartnerListing(id: 'p1', status: 'draft', title: 'Mikocheni'));
    harness.tenancies.tenancies['b1'] = const Tenancy(id: 'b1', stage: TenancyStage.movingIn, tenantName: 'Neema');
    final container = ProviderContainer(overrides: harness.overrides);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).adopt(AuthSessionStub(
          token: 'session-token',
          customer: const Customer(id: 'cust-1', phoneNumber: '+255712345678', fullName: 'Amina', hasPin: true, onboardingComplete: true),
        ));
    final router = container.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: testApp(router)));
    await tester.pumpAndSettle();

    for (final (path, screen) in [
      (Routes.landlordHomes, PartnerListingsScreen),
      (Routes.partnerListingNew(AppRole.landlord), ListingWizardScreen),
      (Routes.partnerListing(AppRole.landlord, 'p1'), PartnerListingScreen),
      (Routes.landlordTenants, TenantsScreen),
      (Routes.landlordTenancy('b1'), TenancyScreen),
      (Routes.landlordMoney, EarningsScreen),
      (Routes.partnerPayouts(AppRole.landlord), PayoutsScreen),
      (Routes.landlordEnquiries, PartnerEnquiriesScreen),
      (Routes.landlordConfirm('p9'), ConfirmListingScreen),
      (Routes.partnerIntro(AppRole.landlord), LandlordIntroScreen),
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(find.byType(screen), findsOneWidget, reason: path);
    }

    router.go(Routes.partnerListingNew(AppRole.landlord));
    await tester.pumpAndSettle();
    expect(find.text('STEP 1 OF 5 · BASICS'), findsOneWidget, reason: 'a landlord has no landlord step');

    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  });
}
