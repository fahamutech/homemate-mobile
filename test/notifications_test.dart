import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/features/broker/presentation/broker_home_screen.dart';
import 'package:homemate_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';
import 'package:homemate_mobile/features/shared/models.dart';
import 'package:homemate_mobile/routing/routes.dart';

import 'support/fakes.dart';

/// One account, one inbox per role: the broker's bell counts the broker's
/// notices, and each notice opens the screen it is about in that role.
void main() {
  AppNotification notice(String id, String title, {String? audience, String? table, String kind = 'system'}) =>
      AppNotification(
        id: id,
        title: title,
        kind: kind,
        createdAt: DateTime(2026, 9, 30),
        audience: audience,
        subjectTable: table,
        subjectId: table == null ? null : 'subject-$id',
      );

  GoRoute stub(String path, String label) => GoRoute(path: path, builder: (_, __) => Scaffold(body: Text(label)));

  group('where a notification leads', () {
    test('an enquiry is the customer’s own enquiry to a customer, the partner screen to a partner', () {
      final enquiry = notice('1', 'New enquiry', table: 'property_inquiries');
      expect(notificationDestination(enquiry, AppRole.customer), Routes.inquiry('subject-1'));
      expect(notificationDestination(enquiry, AppRole.broker), Routes.partnerEnquiry(AppRole.broker, 'subject-1'));
      expect(notificationDestination(enquiry, AppRole.landlord), '/landlord/enquiries/subject-1');
    });

    test('money, payouts and listings open the partner’s own screens', () {
      expect(notificationDestination(notice('2', 'Payment received', table: 'payment_splits'), AppRole.broker),
          Routes.partnerEarning(AppRole.broker, 'subject-2'));
      expect(notificationDestination(notice('3', 'Payout sent', table: 'payouts'), AppRole.landlord),
          Routes.partnerPayouts(AppRole.landlord));
      expect(
          notificationDestination(
              notice('4', 'Your listing is live', table: 'properties', kind: 'listing_update'), AppRole.broker),
          Routes.partnerListing(AppRole.broker, 'subject-4'));
      expect(notificationDestination(notice('5', 'Confirm a listing', table: 'properties'), AppRole.landlord),
          Routes.landlordConfirm('subject-5'));
    });

    test('an identity notice opens the ID screen for a customer, the profile for a partner', () {
      final kyc = notice('6', 'Your identity is verified', table: 'users', kind: 'kyc_update');
      expect(notificationDestination(kyc, AppRole.customer), Routes.identity);
      expect(notificationDestination(kyc, AppRole.broker), Routes.brokerProfile);
    });
  });

  testWidgets('the broker’s bell counts the broker inbox and opens it', (tester) async {
    tester.view.physicalSize = TestHarness.phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.broker, status: 'applied'));
    harness.onboarding.statuses['broker'] = 'pending_review';
    harness.activity.notificationList.addAll([
      notice('1', 'New enquiry', audience: 'broker', table: 'property_inquiries'),
      notice('2', 'You have a reply', audience: 'customer', table: 'property_inquiries'),
      notice('3', 'Your identity is verified', table: 'users'),
    ]);

    await tester.pumpWidget(harness.wrap(const BrokerHomeScreen(), extraRoutes: [
      stub('/broker/notifications', 'BROKER INBOX'),
      stub(Routes.partnerApplication(AppRole.broker), 'APPLICATION'),
    ]));
    await tester.pumpAndSettle();

    expect(find.descendant(of: find.byType(Badge), matching: find.text('2')), findsOneWidget, reason: 'the broker notice and the account notice, not the customer one');
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    expect(find.text('BROKER INBOX'), findsOneWidget);
  });

  testWidgets('the broker inbox leaves the customer’s notices out and opens the partner enquiry', (tester) async {
    final harness = TestHarness();
    harness.activity.notificationList.addAll([
      notice('1', 'New enquiry', audience: 'broker', table: 'property_inquiries', kind: 'enquiry_received'),
      notice('2', 'You have a reply', audience: 'customer', table: 'property_inquiries'),
    ]);

    await tester.pumpWidget(harness.wrap(const NotificationsScreen(role: AppRole.broker), extraRoutes: [
      stub('/broker/enquiries/:id', 'PARTNER ENQUIRY'),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('New enquiry'), findsOneWidget);
    expect(find.text('You have a reply'), findsNothing);

    await tester.tap(find.text('New enquiry'));
    await tester.pumpAndSettle();
    expect(find.text('PARTNER ENQUIRY'), findsOneWidget);
    expect(harness.activity.notificationList.first.isUnread, isFalse);
    expect(harness.activity.notificationList.last.isUnread, isTrue, reason: 'the customer inbox is untouched');
  });
}
