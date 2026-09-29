import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_application.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_enquiry.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_listing.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_money.dart';

/// The shapes below are trimmed from real responses of homemate-functions
/// (partner roles T03–T06, and #7's previews).
void main() {
  test('applications: profile prefill, step completion, remediations, the fee example', () {
    final overview = ApplicationsOverview.fromJson({
      'profile': {
        'fullName': 'Neema Kileo',
        'dateOfBirth': '1990-04-12',
        'nationalIdNumber': '19900412-12345-00001-23',
        'tinNumber': null,
        'physicalAddress': 'Mikocheni',
        'kycStatus': 'in_review',
        'payout': {'method': 'mobile_money', 'provider': 'mpesa', 'accountName': 'Neema Kileo', 'accountNumber': '+255712345678'},
      },
      'applications': [
        {
          'role': 'broker',
          'status': 'applied',
          'steps': [
            {'step': 'details', 'complete': true},
            {'step': 'identity', 'complete': false},
          ],
          'nextStep': 'identity',
          'missingSteps': ['identity', 'payout', 'agreement'],
          'canSubmit': false,
          'canDraftListings': true,
          'currentAgreementVersion': 'v1.0',
        },
      ],
      'remediations': [
        {'id': 'r1', 'issue': 'Your selfie is too dark', 'requestedAction': 'Take a new one', 'documentType': 'selfie'},
      ],
      'feeExample': {'rent': 1200000, 'tenantFee': 600000, 'tenantFeePercentage': 50, 'platformAmount': 60000, 'platformPercentage': 10, 'youReceive': 540000},
    });

    expect(overview.profile.dateOfBirth, DateTime(1990, 4, 12));
    expect(overview.profile.payout!.provider, 'mpesa');
    final broker = overview.application('broker');
    expect(broker.isDone('details'), isTrue);
    expect(broker.isDone('identity'), isFalse);
    expect(broker.isSettingUp, isTrue);
    expect(broker.canDraftListings, isTrue);
    expect(overview.application('landlord').status, 'not_started');
    expect(overview.remediations.single.documentType, 'selfie');
    expect(overview.feeExample!.youReceive, 540000);
  });

  test('details go out with the date as a day', () {
    final json = PartnerDetails(fullName: 'Baraka', dateOfBirth: DateTime(1990, 3, 14), nationalIdNumber: '1').toJson();
    expect(json['dateOfBirth'], '1990-03-14');
  });

  test('a listing: strings to numbers, blockers, the money preview', () {
    final listing = PartnerListing.fromJson({
      'id': 'p1',
      'status': 'draft',
      'title': 'Masaki 2BR',
      'price': '900000.00',
      'depositMonths': '2.0',
      'bedrooms': 2,
      'latitude': null,
      'photos': [
        {'id': 'm2', 'position': 1, 'isCover': false},
        {'id': 'm1', 'position': 0, 'isCover': true, 'url': '/app/media/m1/raw'},
      ],
      'amenities': [
        {'id': 'a1', 'name': 'Parking'},
      ],
      'charges': [
        {'name': 'Water', 'amount': '20000.00', 'frequency': 'monthly', 'isMandatory': true},
      ],
      'listedBy': {'you': true, 'name': 'Neema Kileo'},
      'landlordConfirmation': {'status': 'not_required'},
      'editable': true,
      'submitBlockers': [
        {'code': 'missing_location', 'message': 'Drop the pin on the map.'},
      ],
      'canSubmit': false,
      'moneyPreview': {
        'rent': 900000, 'deposit': 1800000, 'advance': 0, 'firstRent': 900000, 'tenantFee': 450000,
        'tenantFeePercentage': 50, 'saving': 450000, 'total': 3150000,
        'youEarn': {'feeShare': 405000, 'rentAndDeposit': 0, 'total': 405000},
      },
    });
    expect(listing.price, 900000);
    expect(listing.depositMonths, 2);
    expect(listing.hasPin, isFalse);
    expect(listing.photos.first.id, 'm1');
    expect(listing.amenityIds, ['a1']);
    expect(listing.charges.single.amount, 20000);
    expect(listing.submitBlockers.single.code, 'missing_location');
    expect(listing.moneyPreview!.total, 3150000);
    expect(listing.moneyPreview!.youEarn, 405000);
    expect(listing.landlordConfirmationStatus, 'not_required');
  });

  test('an enquiry and its journey', () {
    final journey = EnquiryJourney.fromJson({
      'inquiry': {
        'id': 'i1',
        'status': 'accepted',
        'moveInDate': '2026-10-01',
        'occupants': 2,
        'budgetAmount': '1200000.00',
        'property': {'id': 'p1', 'title': 'Masaki Heights'},
        'customer': {'name': 'Amina Juma', 'idVerified': true, 'phone': '+255712000001'},
        'canAnswer': true,
      },
      'steps': [
        {'key': 'enquiry_received', 'title': 'Enquiry received', 'state': 'done', 'at': '2026-09-28T10:14:00Z'},
        {'key': 'awaiting_payment', 'title': 'Customer to pay', 'state': 'current'},
      ],
      'earning': {'yourShare': 540000, 'tenantFee': 600000},
      'payment': {'firstRent': 1200000, 'deposit': 1200000, 'advance': 0, 'tenantFee': 600000, 'tenantFeePercentage': 50, 'total': 3000000},
    });
    expect(journey.enquiry.customerIdVerified, isTrue);
    expect(journey.enquiry.budgetAmount, 1200000);
    expect(journey.steps.last.state, 'current');
    expect(journey.yourShare, 540000);
    expect(journey.total, 3000000);
    expect(EnquiryOutcome.decline.status, 'rejected');
  });

  test('money: totals by state, the detail with its fee, payouts with a masked account', () {
    final overview = EarningsOverview.fromJson({
      'totals': {'ready': 810000, 'being_checked': 270000},
      'paidThisYear': 3240000,
      'items': [
        {'id': 'e1', 'amount': '810000.00', 'state': 'ready', 'propertyTitle': 'Oyster Bay'},
      ],
    });
    expect(overview.total('ready'), 810000);
    expect(overview.total('paid'), 0);
    expect(overview.items.single.amount, 810000);

    final detail = EarningDetail.fromJson({
      'id': 'e1',
      'amount': '810000.00',
      'state': 'ready',
      'split': [
        {'beneficiary': 'broker', 'amount': '810000', 'you': true},
        {'beneficiary': 'homemate', 'amount': '90000'},
      ],
      'fee': {'monthlyRent': 1800000, 'feePercentage': 50, 'feeAmount': 900000, 'platformPercentage': 10, 'platformAmount': 90000, 'yourShare': 810000},
      'timeline': [
        {'key': 'paid', 'at': '2026-09-26T00:00:00Z', 'done': true},
        {'key': 'paid_out', 'at': null, 'done': false},
      ],
    });
    expect(detail.hasFee, isTrue);
    expect(detail.platformAmount, 90000);
    expect(detail.split.first.you, isTrue);
    expect(detail.timeline.last.done, isFalse);

    final payouts = PayoutsOverview.fromJson({
      'account': {'method': 'mobile_money', 'provider': 'mpesa', 'accountName': 'Neema', 'accountNumber': '•••• 5678'},
      'items': [
        {'id': 'po1', 'amount': '315000', 'status': 'on_hold', 'holdReason': 'Name mismatch'},
      ],
    });
    expect(payouts.hasAccount, isTrue);
    expect(payouts.items.single.holdReason, 'Name mismatch');

    final summary = PartnerSummary.fromJson({
      'counts': {'liveListings': 12, 'openEnquiries': 5, 'earnedThisMonth': 1080000},
      'needsYou': [
        {'kind': 'enquiry', 'title': 'New enquiry', 'subtitle': 'Masaki — Amina', 'targetId': 'i1'},
      ],
    });
    expect(summary.count('liveListings'), 12);
    expect(summary.needsYou.single.kind, 'enquiry');
  });

  test('the details step sends the TIN under the key the server reads (tinNumber)', () {
    final json = PartnerDetails(
      fullName: 'Neema Kileo',
      dateOfBirth: DateTime(1990, 4, 12),
      nationalIdNumber: '19900412-12345-00001-23',
      tinNumber: '123-456-789',
      physicalAddress: 'Mikocheni',
    ).toJson();
    expect(json['tinNumber'], '123-456-789');
    expect(json.containsKey('tin'), isFalse);
  });
}
