import '../i18n/app_text.dart';
import 'api_exception.dart';

/// The sentence a person reads for [error]: the app's own failures (offline,
/// timeout, a bug) in their language; a refusal from the server as the
/// server worded it.
String errorText(AppText text, Object error) {
  if (error is! ApiException) return text.errorUnexpected;
  return switch (error.code) {
    'NETWORK_UNAVAILABLE' => text.errorOffline,
    'TIMEOUT' => text.errorTimeout,
    'UNEXPECTED' => text.errorUnexpected,
    _ => error.message,
  };
}
