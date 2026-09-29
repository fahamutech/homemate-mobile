import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/i18n/app_locale.dart';
import 'package:homemate_mobile/core/i18n/app_text.dart';
import 'package:homemate_mobile/core/network/api_exception.dart';
import 'package:homemate_mobile/core/network/error_text.dart';

/// What a person reads when something fails: the app's own failures in their
/// language, the server's sentence as the server wrote it.
void main() {
  const sw = AppText(AppLocale.swahili);
  const en = AppText(AppLocale.english);

  test('being offline, a timeout and a bug are told in the reader\'s language', () {
    expect(errorText(sw, ApiException.network()), sw.errorOffline);
    expect(errorText(sw, ApiException.timeout()), sw.errorTimeout);
    expect(errorText(sw, ApiException.unexpected()), sw.errorUnexpected);
    expect(errorText(en, ApiException.network()), 'You appear to be offline. Check your connection and try again.');
    expect(sw.errorOffline, isNot(en.errorOffline));
  });

  test('anything that is not an ApiException is the generic sentence, never its toString', () {
    expect(errorText(sw, StateError('boom')), sw.errorUnexpected);
    expect(errorText(en, 42), 'Something went wrong on our side. Please try again.');
  });

  test('the server\'s own message is shown as it came', () {
    final refused = ApiException(code: 'RATE_LIMITED', message: 'Please wait before asking for another code', statusCode: 429);
    expect(errorText(sw, refused), 'Please wait before asking for another code');
  });
}
