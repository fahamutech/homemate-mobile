import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/providers.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The real composition root, with only the HTTP transport replaced.
///
/// Every other test overrides the repositories, so none of them builds the
/// provider graph the app runs. That is how a dependency cycle between the API
/// client and the role controller shipped: Riverpod asserts cycles only in
/// debug builds, so every request of a local `flutter run` failed (sign-in
/// showed "Something went wrong") while the release build worked.
void main() {
  late List<http.Request> sent;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sent = [];
    container = ProviderContainer(overrides: [
      httpClientProvider.overrideWithValue(MockClient((request) async {
        sent.add(request);
        return http.Response(
          jsonEncode({'challengeId': 'c-1', 'expiresAt': '2026-09-30T10:00:00Z', 'resendAfterSeconds': 60}),
          200,
          headers: {'content-type': 'application/json'},
        );
      })),
    ]);
  });

  tearDown(() => container.dispose());

  test('a request goes out through the real provider graph', () async {
    final challenge =
        await container.read(authRepositoryProvider).requestOtp(phoneNumber: '+255712300006');

    expect(challenge.challengeId, 'c-1');
    expect(sent, hasLength(1));
    expect(sent.single.headers.containsKey('x-partner-role'), isFalse);
  });

  test('requests announce the partner role once a partner shell is open', () async {
    await container.read(roleControllerProvider.notifier).open(AppRole.broker);

    await container.read(authRepositoryProvider).requestOtp(phoneNumber: '+255712300006');

    expect(sent.last.headers['x-partner-role'], 'broker');
  });
}
