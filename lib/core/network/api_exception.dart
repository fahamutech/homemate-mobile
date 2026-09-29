/// A failure the user can be told about, separated from a bug.
///
/// The backend already answers with `{error, message}` where the message is
/// written for a person ("Please wait before asking for another code"), so the
/// app shows that rather than inventing its own wording per screen.
class ApiException implements Exception {
  ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.retryAfterSeconds,
    this.details = const {},
  });

  final String code;
  final String message;
  final int? statusCode;

  /// Present on a 429 so a screen can count down instead of just refusing.
  final int? retryAfterSeconds;

  /// What the server added to explain a refusal — `missingSteps` on a partner
  /// application, `reasons` on a listing that is not ready.
  final Map<String, dynamic> details;

  /// A list of sentences from [details], or none.
  List<String> detailList(String key) => [
        for (final item in (details[key] as List? ?? const [])) '$item',
      ];

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isRateLimited => statusCode == 429;
  bool get isConflict => statusCode == 409;

  /// True when retrying the same request might work — the network, or us.
  bool get isTransient =>
      code == 'NETWORK_UNAVAILABLE' || code == 'TIMEOUT' || (statusCode ?? 0) >= 500;

  factory ApiException.network() => ApiException(
    code: 'NETWORK_UNAVAILABLE',
    message: 'You appear to be offline. Check your connection and try again.',
  );

  factory ApiException.timeout() => ApiException(
    code: 'TIMEOUT',
    message: 'That took too long. Please try again.',
  );

  factory ApiException.unexpected() => ApiException(
    code: 'UNEXPECTED',
    message: 'Something went wrong on our side. Please try again.',
  );

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}
