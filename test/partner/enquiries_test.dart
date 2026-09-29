import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_enquiry.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/enquiries/partner_enquiries_screen.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/enquiries/partner_enquiry_screen.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';

import '../support/fakes.dart';

/// BRK-040 list, BRK-041 respond, BRK-041b decline, BRK-042 the accepted journey.
void main() {
  PartnerEnquiry enquiry({String id = 'i1', String status = 'pending', bool canAnswer = true, String name = 'Amina Juma'}) => PartnerEnquiry(
        id: id,
        status: status,
        reference: 'HM-INQ-000412',
        message: 'Hi, is it still available from 1 October?',
        moveInDate: DateTime(2026, 10, 1),
        occupants: 2,
        budgetAmount: 1200000,
        contactPreference: 'whatsapp',
        preferredContactTime: 'Evenings',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        propertyId: 'p1',
        propertyTitle: 'Masaki Heights Residence',
        customerName: name,
        customerIdVerified: true,
        customerPhone: canAnswer ? '+255712000001' : null,
        canAnswer: canAnswer,
      );

  Future<TestHarness> open(WidgetTester tester, Widget screen, void Function(TestHarness) arrange) async {
    tester.view.physicalSize = TestHarness.phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.broker));
    arrange(harness);
    await tester.pumpWidget(harness.wrap(screen, extraRoutes: [
      GoRoute(path: '/broker/enquiries/:id', builder: (_, s) => Scaffold(body: Text('ENQUIRY ${s.pathParameters['id']}'))),
    ]));
    await tester.pumpAndSettle();
    return harness;
  }

  Future<void> tapText(WidgetTester tester, String label) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    final finder = find.text(label).last;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('the list (BRK-040)', () {
    testWidgets('new enquiries with who, what and how to reach them', (tester) async {
      final harness = await open(tester, const PartnerEnquiriesScreen(role: AppRole.broker), (h) {
        h.enquiries.enquiries['i1'] = enquiry();
        h.enquiries.enquiries['i2'] = enquiry(id: 'i2', status: 'accepted', name: 'Grace Mollel');
      });
      expect(find.text('Amina Juma'), findsOneWidget);
      expect(find.text('Grace Mollel'), findsNothing, reason: 'the New tab is first');
      expect(find.textContaining('prefers WhatsApp'), findsOneWidget);
      expect(find.text('Move in 1 Oct'), findsOneWidget);
      expect(find.text('2 people'), findsOneWidget);
      expect(find.text('Budget TZS 1,200,000'), findsOneWidget);

      await tester.tap(find.byTooltip('Call'));
      await tester.tap(find.byTooltip('WhatsApp'));
      expect(harness.contact.calls, ['+255712000001']);
      expect(harness.contact.chats, ['+255712000001']);

      await tester.tap(find.byKey(const ValueKey('enquiry-tab-accepted')));
      await tester.pumpAndSettle();
      expect(find.text('Grace Mollel'), findsOneWidget);
    });

    testWidgets('Reply opens the enquiry', (tester) async {
      await open(tester, const PartnerEnquiriesScreen(role: AppRole.broker), (h) => h.enquiries.enquiries['i1'] = enquiry());
      await tester.tap(find.text('Reply'));
      await tester.pumpAndSettle();
      expect(find.text('ENQUIRY i1'), findsOneWidget);
    });
  });

  group('responding (BRK-041)', () {
    testWidgets('accepting sends the reply and shows the journey', (tester) async {
      final harness = await open(tester, const PartnerEnquiryScreen(role: AppRole.broker, enquiryId: 'i1'), (h) => h.enquiries.enquiries['i1'] = enquiry());
      expect(find.text('ID verified'), findsOneWidget);
      expect(find.text('Evenings'), findsOneWidget);

      await tapText(tester, 'Accept');
      await tester.enterText(find.byKey(const ValueKey('enquiry-reply')), 'Yes, it is available from 1 October.');
      await tapText(tester, 'Send and accept');
      expect(harness.enquiries.responses.single.$2, EnquiryOutcome.accept);

      // BRK-042: the tracker, what she pays, what the broker earns.
      expect(find.text('Journey'), findsOneWidget);
      expect(find.text('What Amina pays'), findsOneWidget);
      expect(find.text('TZS 3,000,000'), findsOneWidget);
      expect(find.text('TZS 540,000'), findsOneWidget);
    });

    testWidgets('a reply needs words', (tester) async {
      final harness = await open(tester, const PartnerEnquiryScreen(role: AppRole.broker, enquiryId: 'i1'), (h) => h.enquiries.enquiries['i1'] = enquiry());
      await tapText(tester, 'Send reply');
      expect(find.text('Write a reply first.'), findsOneWidget);
      expect(harness.enquiries.responses, isEmpty);
    });

    testWidgets('declining needs a reason; a quick reason fills it (BRK-041b)', (tester) async {
      final harness = await open(tester, const PartnerEnquiryScreen(role: AppRole.broker, enquiryId: 'i1'), (h) => h.enquiries.enquiries['i1'] = enquiry());
      await tapText(tester, 'Decline');
      await tapText(tester, 'Decline');
      expect(find.text('Decline this enquiry'), findsOneWidget);

      await tapText(tester, 'Decline enquiry');
      expect(find.text('Say why you are declining.'), findsOneWidget);
      expect(harness.enquiries.responses, isEmpty);

      await tapText(tester, "Move-in date doesn't work");
      await tapText(tester, 'Decline enquiry');
      expect(harness.enquiries.responses.single.$2, EnquiryOutcome.decline);
      expect(harness.enquiries.responses.single.$4, "Move-in date doesn't work");
    });

    testWidgets('closing needs no words, and the answer is shown after', (tester) async {
      final harness = await open(tester, const PartnerEnquiryScreen(role: AppRole.broker, enquiryId: 'i1'), (h) => h.enquiries.enquiries['i1'] = enquiry());
      await tapText(tester, 'Close without replying');
      await tapText(tester, 'Close enquiry');
      expect(harness.enquiries.responses.single.$2, EnquiryOutcome.close);
      expect(harness.enquiries.responses.single.$3, isNull);
      expect(find.text('Close enquiry'), findsNothing, reason: 'a closed enquiry has nothing left to answer');
    });

    testWidgets('a dismissed decline sheet sends nothing', (tester) async {
      final harness = await open(tester, const PartnerEnquiryScreen(role: AppRole.broker, enquiryId: 'i1'), (h) => h.enquiries.enquiries['i1'] = enquiry());
      await tapText(tester, 'Decline');
      await tapText(tester, 'Decline');
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Decline this enquiry'), findsNothing);
      expect(harness.enquiries.responses, isEmpty);
    });

    testWidgets('a landlord whose home a broker listed can read, not answer', (tester) async {
      await open(tester, const PartnerEnquiryScreen(role: AppRole.broker, enquiryId: 'i1'), (h) => h.enquiries.enquiries['i1'] = enquiry(canAnswer: false));
      expect(find.text('The broker who listed this home answers its enquiries.'), findsOneWidget);
      expect(find.text('Send reply'), findsNothing);
      expect(find.byTooltip('Call'), findsNothing);
    });
  });
}
