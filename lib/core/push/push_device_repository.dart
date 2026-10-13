import '../network/api_client.dart';

/// Tells the backend which installs to push to (`/app/devices`).
abstract class PushDeviceRepository {
  Future<void> register({required String token, required String platform, String? appVersion});

  /// Stop pushing to this install — on a sign-out, while the session still works.
  Future<void> unregister(String token);
}

class ApiPushDeviceRepository implements PushDeviceRepository {
  ApiPushDeviceRepository(this._api);

  final ApiClient _api;

  @override
  Future<void> register({required String token, required String platform, String? appVersion}) async {
    await _api.post('/app/devices', body: {'token': token, 'platform': platform, 'appVersion': appVersion});
  }

  @override
  Future<void> unregister(String token) async {
    await _api.post('/app/devices/remove', body: {'token': token});
  }
}
