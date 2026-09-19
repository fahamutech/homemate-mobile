import 'dart:convert';
import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../../shared/models.dart';

/// The customer's own identity evidence and search preferences — the second
/// and third steps of "Complete your profile" (CUS-008a/b).
///
/// Both live here rather than on the auth repository because neither is about
/// signing in: a customer who skips them is still perfectly signed in, they
/// have just told us less.
abstract class IdentityRepository {
  Future<IdentityStatus> identity();

  /// Uploads a document. The bytes go as base64 in the JSON body, the way the
  /// backoffice already sends them — the app holds no storage credentials and
  /// must never be given any.
  Future<IdentityDocument> uploadDocument({
    required String documentType,
    required Uint8List bytes,
    required String contentType,
    String? filename,
  });

  Future<void> setPhoto({
    required Uint8List bytes,
    required String contentType,
    String? filename,
  });

  Future<CustomerPreferences> preferences();
  Future<CustomerPreferences> savePreferences(CustomerPreferences preferences);
}

class HttpIdentityRepository implements IdentityRepository {
  HttpIdentityRepository(this._api);

  final ApiClient _api;

  @override
  Future<IdentityStatus> identity() async =>
      IdentityStatus.fromJson(await _api.get('/app/me/kyc'));

  @override
  Future<IdentityDocument> uploadDocument({
    required String documentType,
    required Uint8List bytes,
    required String contentType,
    String? filename,
  }) async =>
      IdentityDocument.fromJson(await _api.post('/app/me/kyc/documents', body: {
        'documentType': documentType,
        'file': {
          'base64': base64Encode(bytes),
          'contentType': contentType,
          'name': filename,
        },
      }));

  @override
  Future<void> setPhoto({
    required Uint8List bytes,
    required String contentType,
    String? filename,
  }) async {
    await _api.put('/app/me/photo', body: {
      'image': {
        'base64': base64Encode(bytes),
        'contentType': contentType,
        'name': filename,
      },
    });
  }

  @override
  Future<CustomerPreferences> preferences() async =>
      CustomerPreferences.fromJson(await _api.get('/app/preferences'));

  @override
  Future<CustomerPreferences> savePreferences(CustomerPreferences preferences) async =>
      CustomerPreferences.fromJson(
        await _api.put('/app/preferences', body: preferences.toJson()),
      );
}
