import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import 'api_exception.dart';

/// Where the session token comes from, and what to do when the server says it
/// is no longer good. Keeping this an interface means the client does not know
/// about storage, and storage does not know about HTTP.
abstract class SessionSource {
  String? get token;

  /// Called when the API rejects the token, so the app can return to sign-in
  /// once rather than every screen discovering it separately.
  Future<void> onSessionRejected();
}

/// The single place the app talks to the backend.
///
/// It does four things and nothing else: attach the session, encode and decode
/// JSON, turn every failure into an [ApiException] carrying a sentence worth
/// showing, and hand a 401 back to whoever owns the session. Screens and
/// repositories never touch `http` directly, so a change of transport, a
/// retry policy or a header is one edit here.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
    this.session,
    Duration? timeout,
  })  : _http = httpClient ?? http.Client(),
        _baseUrl = (baseUrl ?? Env.apiBaseUrl).replaceAll(RegExp(r'/+$'), ''),
        _timeout = timeout ?? const Duration(seconds: Env.requestTimeoutSeconds);

  final http.Client _http;
  final String _baseUrl;
  final Duration _timeout;
  final SessionSource? session;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  /// Bytes rather than JSON — listing images come through the API because the
  /// object store needs credentials the app must not hold.
  Future<List<int>> getBytes(String path, {Map<String, dynamic>? query}) async {
    final response = await _perform(() => _http.get(_uri(path, query), headers: _headers()));
    if (response.statusCode >= 400) throw _failure(response);
    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
  }) async {
    final uri = _uri(path, query);
    final headers = _headers(hasBody: body != null);
    final encoded = body == null ? null : jsonEncode(body);

    final response = await _perform(() {
      switch (method) {
        case 'GET':
          return _http.get(uri, headers: headers);
        case 'POST':
          return _http.post(uri, headers: headers, body: encoded);
        case 'PUT':
          return _http.put(uri, headers: headers, body: encoded);
        case 'DELETE':
          return _http.delete(uri, headers: headers);
        default:
          throw ArgumentError('Unsupported method $method');
      }
    });

    if (response.statusCode == 401) {
      // The token is gone or expired. Tell the session owner once; the caller
      // still gets an error so it does not carry on as though it had data.
      await session?.onSessionRejected();
      throw _failure(response);
    }
    if (response.statusCode >= 400) throw _failure(response);

    return _decode(response);
  }

  Future<http.Response> _perform(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on TimeoutException {
      throw ApiException.timeout();
    } on ApiException {
      rethrow;
    } catch (_) {
      // Anything the socket layer throws means we could not reach the server;
      // the user does not care which exception type it was.
      throw ApiException.network();
    }
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleaned = <String, String>{};
    query?.forEach((key, value) {
      if (value == null) return;
      final text = value is Iterable ? value.join(',') : '$value';
      if (text.isEmpty) return;
      cleaned[key] = text;
    });
    return Uri.parse('$_baseUrl$path').replace(
      queryParameters: cleaned.isEmpty ? null : cleaned,
    );
  }

  Map<String, String> _headers({bool hasBody = false}) => {
        if (hasBody) 'content-type': 'application/json',
        'accept': 'application/json',
        if (session?.token case final token?) 'authorization': 'Bearer $token',
      };

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return const {};
    final decoded = jsonDecode(response.body);
    // Some endpoints answer with a bare list; wrapping keeps one return type.
    if (decoded is List) return {'items': decoded};
    if (decoded is Map<String, dynamic>) return decoded;
    return {'value': decoded};
  }

  ApiException _failure(http.Response response) {
    Map<String, dynamic> payload = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } catch (_) {
      // A non-JSON error body (a proxy's HTML, say) tells the user nothing.
    }

    final retryAfter = int.tryParse(response.headers['retry-after'] ?? '');
    return ApiException(
      code: payload['error'] as String? ?? 'UNEXPECTED',
      // The backend writes these for people, so prefer its wording.
      message: payload['message'] as String? ?? ApiException.unexpected().message,
      statusCode: response.statusCode,
      retryAfterSeconds: retryAfter,
    );
  }

  void close() => _http.close();
}
