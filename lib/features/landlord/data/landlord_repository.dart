import '../../../core/network/api_client.dart';
import '../../shared/journey_models.dart' show LeaseAgreement;
import 'landlord_lease.dart';
import 'listing_confirmation.dart';
import 'tenancy.dart';

/// LND-003: homes a broker listed in the landlord's name.
abstract class ConfirmationsRepository {
  Future<List<ListingConfirmation>> list();
  Future<void> confirm(String propertyId);
  Future<void> dispute(String propertyId, {required String reason});
}

/// LND-030–033: the landlord's tenancies, starting and ending them.
abstract class TenanciesRepository {
  Future<List<Tenancy>> list({TenancyStage? stage});
  Future<Tenancy> get(String id);
  Future<Tenancy> moveIn(String id, {required DateTime date});
  Future<Tenancy> end(String id, {required DateTime date, String? reason});

  /// LND-033: the lease behind a tenancy.
  Future<LeaseAgreement> lease(String id);
}

class HttpConfirmationsRepository implements ConfirmationsRepository {
  HttpConfirmationsRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<ListingConfirmation>> list() async {
    final json = await _api.get('/app/landlord/confirmations');
    return [for (final row in (json['items'] as List? ?? const [])) ListingConfirmation.fromJson(row as Map<String, dynamic>)];
  }

  @override
  Future<void> confirm(String propertyId) => _api.post('/app/landlord/listings/$propertyId/confirm');

  @override
  Future<void> dispute(String propertyId, {required String reason}) =>
      _api.post('/app/landlord/listings/$propertyId/dispute', body: {'reason': reason});
}

class HttpTenanciesRepository implements TenanciesRepository {
  HttpTenanciesRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Tenancy>> list({TenancyStage? stage}) async {
    final json = await _api.get('/app/landlord/tenancies', query: {'status': stage?.code});
    return [for (final row in (json['items'] as List? ?? const [])) Tenancy.fromJson(row as Map<String, dynamic>)];
  }

  @override
  Future<Tenancy> get(String id) async => Tenancy.fromJson(await _api.get('/app/landlord/tenancies/$id'));

  @override
  Future<Tenancy> moveIn(String id, {required DateTime date}) async =>
      Tenancy.fromJson(await _api.post('/app/landlord/tenancies/$id/move-in', body: {'date': isoDay(date)}));

  @override
  Future<Tenancy> end(String id, {required DateTime date, String? reason}) async => Tenancy.fromJson(
      await _api.post('/app/landlord/tenancies/$id/end', body: {'date': isoDay(date), 'reason': reason}));

  @override
  Future<LeaseAgreement> lease(String id) async => leaseFromLandlordJson(await _api.get('/app/landlord/tenancies/$id/lease'));
}
