import 'dart:convert';

import '../../../core/network/api_client.dart';
import 'partner_listing.dart';

/// A partner's listings (T04). The role comes from the session: the token's
/// active role, or `X-Partner-Role` for an applicant.
abstract class ListingsRepository {
  Future<List<PartnerListingSummary>> list({String? status});
  Future<PartnerListing> get(String id);
  Future<PartnerListing> create(Map<String, dynamic> fields);

  /// Every wizard step saves through this.
  Future<PartnerListing> update(String id, Map<String, dynamic> fields);
  Future<PartnerListing> addPhoto(String id, PhotoUpload photo);
  Future<PartnerListing> removePhoto(String id, String mediaId);

  /// 422 with `details.reasons` when something is missing.
  Future<PartnerListing> submit(String id);
  Future<PartnerListing> archive(String id);

  Future<LandlordCard?> lookupLandlord(String phone);
  Future<LandlordCard> inviteLandlord({required String fullName, required String phone});
}

class HttpListingsRepository implements ListingsRepository {
  HttpListingsRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<PartnerListingSummary>> list({String? status}) async {
    final json = await _api.get('/app/partner/listings', query: {'status': status});
    return [for (final row in (json['items'] as List? ?? const [])) PartnerListingSummary.fromJson(row as Map<String, dynamic>)];
  }

  @override
  Future<PartnerListing> get(String id) async => PartnerListing.fromJson(await _api.get('/app/partner/listings/$id'));

  @override
  Future<PartnerListing> create(Map<String, dynamic> fields) async =>
      PartnerListing.fromJson(await _api.post('/app/partner/listings', body: fields));

  @override
  Future<PartnerListing> update(String id, Map<String, dynamic> fields) async =>
      PartnerListing.fromJson(await _api.put('/app/partner/listings/$id', body: fields));

  @override
  Future<PartnerListing> addPhoto(String id, PhotoUpload photo) async {
    final file = {'base64': base64Encode(photo.bytes), 'contentType': photo.contentType, 'name': photo.name};
    return PartnerListing.fromJson(
      await _api.post('/app/partner/listings/$id/photos', body: {'image': file, 'thumbnail': file}),
    );
  }

  @override
  Future<PartnerListing> removePhoto(String id, String mediaId) async =>
      PartnerListing.fromJson(await _api.delete('/app/partner/listings/$id/photos/$mediaId'));

  @override
  Future<PartnerListing> submit(String id) async =>
      PartnerListing.fromJson(await _api.post('/app/partner/listings/$id/submit'));

  @override
  Future<PartnerListing> archive(String id) async =>
      PartnerListing.fromJson(await _api.post('/app/partner/listings/$id/archive'));

  @override
  Future<LandlordCard?> lookupLandlord(String phone) async {
    final json = await _api.get('/app/partner/landlords/lookup', query: {'phone': phone});
    return json['found'] == true ? LandlordCard.fromJson(json['landlord']) : null;
  }

  @override
  Future<LandlordCard> inviteLandlord({required String fullName, required String phone}) async {
    final json = await _api.post('/app/partner/landlords/invite', body: {'fullName': fullName, 'phone': phone});
    return LandlordCard.fromJson(json['landlord'])!;
  }
}
