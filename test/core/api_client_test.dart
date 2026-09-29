import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/network/api_client.dart';
import 'package:homemate_mobile/core/network/api_exception.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Session implements SessionSource {
  _Session({this.partnerRole});

  @override
  String? get token => 'tok';

  @override
  final String? partnerRole;

  @override
  Future<void> onSessionRejected() async {}
}

void main() {
  test('a partner shell names its role on every request; the customer app does not', () async {
    final seen = <String?>[];
    http.Client client() => MockClient((request) async {
          seen.add(request.headers['x-partner-role']);
          return http.Response('{}', 200);
        });

    await ApiClient(httpClient: client(), baseUrl: 'http://api', session: _Session(partnerRole: 'landlord')).get('/app/partner/listings');
    await ApiClient(httpClient: client(), baseUrl: 'http://api', session: _Session()).get('/app/me');
    expect(seen, ['landlord', null]);
  });

  test('a refusal keeps the server’s details, e.g. what is missing', () async {
    final api = ApiClient(
      baseUrl: 'http://api',
      session: _Session(),
      httpClient: MockClient((_) async => http.Response(
            jsonEncode({
              'error': 'VALIDATION_FAILED',
              'message': 'This listing is not ready',
              'details': {'reasons': ['Add at least 3 photos', 'Pick a landlord']},
            }),
            422,
          )),
    );
    await expectLater(
      api.post('/app/partner/listings/1/submit'),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'status', 422)
          .having((e) => e.details['reasons'], 'reasons', ['Add at least 3 photos', 'Pick a landlord'])),
    );
  });
}
