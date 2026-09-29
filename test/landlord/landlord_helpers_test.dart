import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/i18n/app_locale.dart';
import 'package:homemate_mobile/core/i18n/app_text.dart';
import 'package:homemate_mobile/design/widgets/hm_badge.dart';
import 'package:homemate_mobile/features/landlord/data/tenancy.dart';
import 'package:homemate_mobile/features/landlord/presentation/confirm/dispute_sheet.dart';
import 'package:homemate_mobile/features/landlord/presentation/tenants/tenancy_copy.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/listings/partner_listing_tile.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';

void main() {
  const en = AppText(AppLocale.english);
  const sw = AppText(AppLocale.swahili);
  final today = DateTime(2026, 9, 29, 17, 30);

  test('every stage has a label, a tone and an empty sentence, in both languages', () {
    for (final stage in TenancyStage.values) {
      expect(tenancyStageLabel(sw, stage), isNotEmpty);
      expect(tenancyStageEmpty(sw, stage), isNotEmpty);
    }
    expect(tenancyStageTone(TenancyStage.movingIn), HmBadgeTone.warning);
    expect(tenancyStageTone(TenancyStage.current), HmBadgeTone.success);
    expect(tenancyStageTone(TenancyStage.past), HmBadgeTone.neutral);
  });

  test('the date that matters at each stage, or none', () {
    expect(tenancyWhen(en, Tenancy(id: 'b', stage: TenancyStage.movingIn, leaseStartDate: DateTime(2026, 10, 1))), 'Moves in 1 Oct');
    expect(tenancyWhen(en, Tenancy(id: 'b', stage: TenancyStage.current, nextPaymentDate: DateTime(2026, 11, 1))), 'Next rent 1 Nov');
    expect(tenancyWhen(en, Tenancy(id: 'b', stage: TenancyStage.past, endedOn: DateTime(2026, 9, 30))), 'Ended 30 Sep');
    for (final stage in TenancyStage.values) {
      expect(tenancyWhen(en, Tenancy(id: 'b', stage: stage)), isNull);
    }
  });

  test('a move-in can be confirmed from a week before the lease up to today', () {
    final window = moveInWindow(Tenancy(id: 'b', stage: TenancyStage.movingIn, leaseStartDate: DateTime(2026, 9, 20)), today);
    expect(window.first, DateTime(2026, 9, 13));
    expect(window.last, DateTime(2026, 9, 29));
  });

  test('a lease starting after next week: only today can be picked, the server says why', () {
    final window = moveInWindow(Tenancy(id: 'b', stage: TenancyStage.movingIn, leaseStartDate: DateTime(2026, 12, 1)), today);
    expect(window.first, window.last);
  });

  test('with no lease start, a move-in may be up to a year back', () {
    expect(moveInWindow(const Tenancy(id: 'b', stage: TenancyStage.movingIn), today).first, DateTime(2025, 9, 29));
  });

  test('a tenancy ends between its move-in (or lease start) and today', () {
    expect(endWindow(Tenancy(id: 'b', stage: TenancyStage.current, moveInDate: DateTime(2026, 1, 3), leaseStartDate: DateTime(2026, 1, 1)), today).first, DateTime(2026, 1, 3));
    expect(endWindow(Tenancy(id: 'b', stage: TenancyStage.current, leaseStartDate: DateTime(2026, 1, 1)), today).first, DateTime(2026, 1, 1));
    expect(endWindow(const Tenancy(id: 'b', stage: TenancyStage.current), today).first.isBefore(DateTime(2022)), isTrue);
    expect(endWindow(Tenancy(id: 'b', stage: TenancyStage.current, moveInDate: DateTime(2027)), today).first, DateTime(2026, 9, 29));
  });

  test('who listed a home: the landlord is always told, the broker only of others', () {
    expect(listedByLine(en, AppRole.landlord, true, null), 'Listed by you');
    expect(listedByLine(en, AppRole.landlord, false, 'Juma'), 'Listed by Juma (broker)');
    expect(listedByLine(en, AppRole.broker, true, 'Juma'), isNull);
    expect(listedByLine(en, AppRole.broker, false, 'Amina'), 'Amina');
  });

  test('four quick dispute reasons in both languages', () {
    expect(quickDisputeReasons(en), hasLength(4));
    expect(quickDisputeReasons(sw).toSet(), hasLength(4));
  });
}
