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
  });

  final String code;
  final String message;
  final int? statusCode;

  /// Present on a 429 so a screen can count down instead of just refusing.
  final int? retryAfterSeconds;

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
