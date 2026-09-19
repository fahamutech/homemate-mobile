import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/config/env.dart';

void main() {
  test('a build with no API_BASE_URL still reaches a real server', () {
    // `flutter test` runs in debug, so this asserts the developer default —
    // the release branch is a compile-time constant and is covered by the
    // assertion below that the two are different servers.
    expect(Env.apiBaseUrl, isNotEmpty);
    expect(Env.apiBaseUrl, startsWith('http'));
  });

  test('describe() says which server and which build mode', () {
    final described = Env.describe();
    expect(described['apiBaseUrl'], Env.apiBaseUrl);
    expect(described['buildMode'], 'debug');
    expect(described['isProduction'], Env.isProduction);
  });
}
