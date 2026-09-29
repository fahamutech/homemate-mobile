import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/features/landlord/data/listing_confirmation.dart';
import 'package:homemate_mobile/features/landlord/data/tenancy.dart';

/// The landlord's API shapes (T04 confirmations, T05 tenancies) as the app reads them.
void main() {
  test('a listing waiting for confirmation reads its broker and terms', () {
    final c = ListingConfirmation.fromJson({
      'propertyId': 'p1',
      'referenceCode': 'HM-P-0001',
      'title': 'Masaki Heights',
      'addressLine': 'Plot 12, Haile Selassie Rd',
      'regionName': 'Dar es Salaam',
      'broker': {'userId': 'b1', 'name': 'Juma Broker'},
      'terms': {'price': '1200000.00', 'currency': 'TZS', 'depositMonths': 2, 'advanceRentMonths': '0', 'minLeaseMonths': 6, 'paymentFrequency': 'monthly', 'availableFrom': '2026-10-01'},
      'requestedAt': '2026-09-28T08:00:00Z',
    });
    expect(c.brokerName, 'Juma Broker');
    expect(c.price, 1200000);
    expect(c.depositMonths, 2);
    expect(c.minLeaseMonths, 6);
    expect(c.availableFrom, DateTime(2026, 10, 1));
    expect(c.place, 'Plot 12, Haile Selassie Rd, Dar es Salaam');
    expect(ListingConfirmation.fromJson({'propertyId': 'p2'}).brokerName, isNull);
    expect(const ListingConfirmation(propertyId: 'p', title: 't').place, '');
  });

  test('a tenancy reads its tenant, home, money and payments', () {
    final t = Tenancy.fromJson({
      'id': 'b1',
      'stage': 'moving_in',
      'status': 'confirmed',
      'tenant': {'id': 'c1', 'name': 'Neema Mushi', 'phone': '+255712000009'},
      'property': {'id': 'p1', 'title': 'Masaki Heights', 'address': 'Masaki'},
      'monthlyRent': '800000.00',
      'depositAmount': '1600000.00',
      'leaseMonths': 12,
      'leaseStartDate': '2026-10-01',
      'nextPaymentDate': '2026-11-01',
      'monthsRemaining': 12,
      'payments': [
        {'id': 'pay1', 'reference': 'HM-PAY-1', 'amount': '2400000.00', 'currency': 'TZS', 'status': 'successful', 'customer_state': 'paid'},
        'ignored',
      ],
    });
    expect(t.stage, TenancyStage.movingIn);
    expect(t.tenantName, 'Neema Mushi');
    expect(t.monthlyRent, 800000);
    expect(t.payments.single.amount, 2400000);
    expect(t.canConfirmMoveIn, isTrue);
    expect(t.canEnd, isFalse);
  });

  test('stages: only moving-in starts, only current ends; unknown is past', () {
    expect(TenancyStage.fromCode('current'), TenancyStage.current);
    expect(TenancyStage.fromCode('weird'), TenancyStage.past);
    expect(TenancyStage.fromCode(null), TenancyStage.past);
    const current = Tenancy(id: 'b', stage: TenancyStage.current);
    const past = Tenancy(id: 'b', stage: TenancyStage.past);
    expect(current.canEnd, isTrue);
    expect(current.canConfirmMoveIn, isFalse);
    expect(past.canEnd, isFalse);
    expect(past.canConfirmMoveIn, isFalse);
  });

  test('a day goes to the server as YYYY-MM-DD', () {
    expect(isoDay(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
  });
}
