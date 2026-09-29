import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/design/widgets/hm_feedback.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_application.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/setup/application_status_screen.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/setup/partner_setup_screen.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/setup/setup_step.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';
import 'package:homemate_mobile/routing/routes.dart';

import '../support/fakes.dart';

/// BRK-002a–e: the broker setup, step by step, against the fake backend.
void main() {
  final statusRoute = GoRoute(
    path: Routes.partnerApplication(AppRole.broker),
    builder: (_, __) => const ApplicationStatusScreen(role: AppRole.broker),
  );

  Future<void> open(WidgetTester tester, TestHarness harness, SetupStep step) async {
    tester.view.physicalSize = TestHarness.phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(harness.wrap(
      PartnerSetupScreen(role: AppRole.broker, initialStep: step),
      extraRoutes: [statusRoute],
    ));
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.scrollUntilVisible(find.byKey(ValueKey(key)), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    // A snackbar from the last action floats over the pinned buttons; let it go.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    final finder = find.text(label);
    await tester.ensureVisible(finder.last);
    await tester.tap(finder.last);
    await tester.pumpAndSettle();
  }

  group('step 1 · your details', () {
    testWidgets('prefilled from the profile, saved on Continue, then identity', (tester) async {
      final harness = TestHarness();
      harness.onboarding.profile = PartnerProfile(
        fullName: 'Baraka Mwinyi',
        dateOfBirth: DateTime(1990, 3, 14),
        nationalIdNumber: '19900314-11101-00001-24',
        physicalAddress: 'Sinza Mori, Ubungo',
      );
      await open(tester, harness, SetupStep.details);

      expect(find.text('STEP 1 OF 3 · YOUR DETAILS'), findsOneWidget);
      expect(find.text('Baraka Mwinyi'), findsOneWidget);
      expect(find.text('19900314-11101-00001-24'), findsOneWidget);

      await tapButton(tester, 'Continue');
      expect(harness.onboarding.details['broker'], isTrue);
      expect(harness.onboarding.statuses['broker'], 'applied');
      expect(find.text('Verify your identity'), findsOneWidget);
    });

    testWidgets('missing fields are named and nothing is saved', (tester) async {
      final harness = TestHarness();
      harness.onboarding.profile = const PartnerProfile(fullName: 'Baraka Mwinyi');
      await open(tester, harness, SetupStep.details);
      await tapButton(tester, 'Continue');
      expect(find.text('Fill in your name, date of birth, NIDA number and where you live.'), findsOneWidget);
      expect(harness.onboarding.details['broker'], isNull);
    });
  });

  group('step 2 · identity', () {
    testWidgets('a verified customer carries the ID over and only adds what is missing', (tester) async {
      final harness = TestHarness();
      harness.identity.kycStatus = 'verified';
      harness.onboarding.profile = const PartnerProfile(fullName: 'Baraka', kycStatus: 'verified');
      await open(tester, harness, SetupStep.identity);

      expect(find.text('You already verified your ID as a customer, so it carries over. We only ask for what is missing.'), findsOneWidget);
      expect(find.text('Verified'), findsWidgets);
    });

    testWidgets('taking the selfie sends it and marks it in review', (tester) async {
      final harness = TestHarness();
      await open(tester, harness, SetupStep.identity);
      expect(find.text('Needed'), findsNWidgets(2));

      await tapButton(tester, 'Take photo');
      expect(harness.identity.uploads, ['selfie']);
      expect(find.text('In review'), findsOneWidget);
    });

    testWidgets('"Do this later" moves on to getting paid', (tester) async {
      final harness = TestHarness();
      await open(tester, harness, SetupStep.identity);
      await tapButton(tester, 'Do this later');
      expect(find.text('Where should we send your earnings?'), findsOneWidget);
    });
  });

  group('step 3 · getting paid', () {
    testWidgets('the example comes from the server, and the agreement must be ticked', (tester) async {
      final harness = TestHarness();
      await open(tester, harness, SetupStep.payout);

      expect(find.text('How you earn — an example'), findsOneWidget);
      expect(find.text('TZS 540,000'), findsOneWidget);
      expect(find.text('Tenant fee (50% of one month)'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('payout-number')), '0712345678');
      await tester.enterText(find.byKey(const ValueKey('payout-name')), 'BARAKA MWINYI');
      await tapButton(tester, 'Submit for review');
      expect(find.text('Please accept the partner agreement.'), findsOneWidget);
      expect(harness.onboarding.submitted, isEmpty);
    });

    testWidgets('submitting with the identity missing says so; with everything done it goes for review', (tester) async {
      final harness = TestHarness();
      harness.onboarding.details['broker'] = true;
      harness.onboarding.statuses['broker'] = 'applied';
      await open(tester, harness, SetupStep.payout);

      await tester.enterText(find.byKey(const ValueKey('payout-number')), '0712345678');
      await tester.enterText(find.byKey(const ValueKey('payout-name')), 'BARAKA MWINYI');
      await tapKey(tester, 'agreement');
      await tapButton(tester, 'Submit for review');
      expect(find.text('Finish these steps first: Identity'), findsOneWidget);
      expect(harness.onboarding.profile.payout!.provider, 'mpesa', reason: 'the payout was still saved');

      await harness.identity.uploadDocument(documentType: 'national_id', bytes: Uint8ListStub.bytes, contentType: 'image/jpeg');
      await harness.identity.uploadDocument(documentType: 'selfie', bytes: Uint8ListStub.bytes, contentType: 'image/jpeg');
      await tapButton(tester, 'Submit for review');
      expect(harness.onboarding.submitted, ['broker']);
      expect(find.text("We're checking your details"), findsOneWidget);
    });

    testWidgets('a bank account instead of mobile money', (tester) async {
      final harness = TestHarness();
      await open(tester, harness, SetupStep.payout);
      await tester.tap(find.text('Bank account'));
      await tester.pumpAndSettle();
      expect(find.text('Account number'), findsOneWidget);
      await tester.tap(find.text('CRDB Bank'));
      await tester.enterText(find.byKey(const ValueKey('payout-number')), '0150123456789');
      await tester.enterText(find.byKey(const ValueKey('payout-name')), 'BARAKA MWINYI');
      await tapKey(tester, 'agreement');
      await tapButton(tester, 'Submit for review');
      expect(harness.onboarding.profile.payout!.method, 'bank');
      expect(harness.onboarding.profile.payout!.provider, 'crdb');
    });
  });

  group('after submitting', () {
    Future<void> openStatus(WidgetTester tester, TestHarness harness) async {
      tester.view.physicalSize = TestHarness.phone * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(harness.wrap(const ApplicationStatusScreen(role: AppRole.broker)));
      await tester.pumpAndSettle();
    }

    testWidgets('under review: the step list, and drafts are allowed', (tester) async {
      final harness = TestHarness();
      harness.onboarding.details['broker'] = true;
      harness.onboarding.statuses['broker'] = 'pending_review';
      harness.onboarding.agreements['broker'] = 'v1.0';
      harness.onboarding.profile = const PartnerProfile(
        fullName: 'Baraka',
        payout: PayoutAccount(method: 'mobile_money', provider: 'mpesa', accountNumber: '+255712345678'),
      );
      await openStatus(tester, harness);

      expect(find.text("We're checking your details"), findsOneWidget);
      expect(find.text("We'll send you an SMS as soon as your Broker account is verified."), findsOneWidget);
      expect(find.text('M-Pesa •••• 678'), findsOneWidget);
      expect(find.text('Draft your first listing'), findsOneWidget);
      expect(find.text('Back to the customer app'), findsOneWidget);
    });

    testWidgets('action needed: what to fix, fixed from here, sent again', (tester) async {
      final harness = TestHarness();
      harness.onboarding.details['broker'] = true;
      harness.onboarding.statuses['broker'] = 'action_needed';
      harness.onboarding.agreements['broker'] = 'v1.0';
      harness.onboarding.profile = const PartnerProfile(
        fullName: 'Baraka',
        payout: PayoutAccount(method: 'mobile_money', provider: 'mpesa', accountNumber: '+255712345678', accountName: 'B'),
      );
      await harness.identity.uploadDocument(documentType: 'national_id', bytes: Uint8ListStub.bytes, contentType: 'image/jpeg');
      harness.onboarding.remediations = const [
        Remediation(id: 'r1', issue: 'Your selfie is too dark to match with your ID.', requestedAction: 'Take a new selfie facing a window.', documentType: 'selfie'),
      ];
      await openStatus(tester, harness);

      expect(find.text('We need one more thing'), findsOneWidget);
      expect(find.text('Your selfie is too dark to match with your ID.'), findsOneWidget);
      expect(find.text('Take a new selfie facing a window.'), findsOneWidget);

      await tapButton(tester, 'Take a new selfie');
      expect(harness.identity.uploads, contains('selfie'));
      await tapButton(tester, 'Send for checking again');
      final errors = tester.widgetList<Text>(find.descendant(of: find.byType(HmInlineError), matching: find.byType(Text)));
      expect(errors.map((t) => t.data), isEmpty);
      expect(harness.onboarding.statuses['broker'], 'pending_review');
    });

    testWidgets('rejected: the reason is shown', (tester) async {
      final harness = TestHarness();
      harness.onboarding.statuses['broker'] = 'rejected';
      await openStatus(tester, harness);
      expect(find.text('Your application was not approved'), findsOneWidget);
    });
  });
}

/// Bytes for a document a test uploads directly.
class Uint8ListStub {
  static final bytes = Uint8List.fromList(const [1, 2, 3]);
}
