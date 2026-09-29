import 'package:homemate_mobile/core/network/api_exception.dart';
import 'package:homemate_mobile/features/landlord/data/landlord_repository.dart';
import 'package:homemate_mobile/features/landlord/data/listing_confirmation.dart';
import 'package:homemate_mobile/features/landlord/data/tenancy.dart';

ApiException _invalid(String message) => ApiException(code: 'VALIDATION_FAILED', message: message, statusCode: 400);

/// Listings waiting for the landlord's word, and what they said.
class FakeConfirmationsRepository implements ConfirmationsRepository {
  final Map<String, ListingConfirmation> waiting = {};
  final List<String> confirmed = [];
  final List<(String, String)> disputed = [];

  @override
  Future<List<ListingConfirmation>> list() async => waiting.values.toList();

  @override
  Future<void> confirm(String propertyId) async {
    if (waiting.remove(propertyId) == null) {
      throw ApiException(code: 'NOT_FOUND', message: 'A listing waiting for your answer not found', statusCode: 404);
    }
    confirmed.add(propertyId);
  }

  @override
  Future<void> dispute(String propertyId, {required String reason}) async {
    if (reason.trim().isEmpty) throw _invalid('Say why this listing is wrong');
    if (waiting.remove(propertyId) == null) {
      throw ApiException(code: 'NOT_FOUND', message: 'A listing waiting for your answer not found', statusCode: 404);
    }
    disputed.add((propertyId, reason));
  }
}

/// The landlord's tenancies, moved along the way the server would.
class FakeTenanciesRepository implements TenanciesRepository {
  final Map<String, Tenancy> tenancies = {};
  final List<(String, DateTime)> movedIn = [];
  final List<(String, DateTime, String?)> ended = [];

  @override
  Future<List<Tenancy>> list({TenancyStage? stage}) async =>
      [for (final t in tenancies.values) if (stage == null || t.stage == stage) t];

  @override
  Future<Tenancy> get(String id) async =>
      tenancies[id] ?? (throw ApiException(code: 'NOT_FOUND', message: 'Tenancy not found', statusCode: 404));

  @override
  Future<Tenancy> moveIn(String id, {required DateTime date}) async {
    final current = await get(id);
    if (!current.canConfirmMoveIn) throw ApiException(code: 'CONFLICT', message: 'Only a tenancy moving in can start', statusCode: 409);
    movedIn.add((id, date));
    return tenancies[id] = _copy(current, stage: TenancyStage.current, status: 'active', moveInDate: date);
  }

  @override
  Future<Tenancy> end(String id, {required DateTime date, String? reason}) async {
    final current = await get(id);
    if (!current.canEnd) throw ApiException(code: 'CONFLICT', message: 'Only a current tenancy can end', statusCode: 409);
    ended.add((id, date, reason));
    return tenancies[id] = _copy(current, stage: TenancyStage.past, status: 'completed', endedOn: date, endReason: reason);
  }

  Tenancy _copy(Tenancy t, {required TenancyStage stage, required String status, DateTime? moveInDate, DateTime? endedOn, String? endReason}) => Tenancy(
        id: t.id,
        stage: stage,
        status: status,
        reference: t.reference,
        tenantName: t.tenantName,
        tenantPhone: t.tenantPhone,
        propertyId: t.propertyId,
        propertyTitle: t.propertyTitle,
        propertyAddress: t.propertyAddress,
        monthlyRent: t.monthlyRent,
        currency: t.currency,
        depositAmount: t.depositAmount,
        leaseMonths: t.leaseMonths,
        leaseStartDate: t.leaseStartDate,
        leaseEndDate: t.leaseEndDate,
        moveInDate: moveInDate ?? t.moveInDate,
        endedOn: endedOn ?? t.endedOn,
        endReason: endReason ?? t.endReason,
        amountPaid: t.amountPaid,
        amountOutstanding: t.amountOutstanding,
        nextPaymentDate: t.nextPaymentDate,
        monthsRemaining: t.monthsRemaining,
        agreementReference: t.agreementReference,
        payments: t.payments,
      );
}
