import 'package:flutter/foundation.dart';

/// Everything that differs between a laptop, staging and a shop phone.
///
/// Values arrive as compile-time `--dart-define`s rather than a bundled file:
/// a Flutter web build is downloadable, so anything baked into an asset is
/// public. Nothing here is a secret.
class Env {
  const Env._();

  /// The deployed backend. A release build that nobody configured must reach
  /// this rather than `localhost` — a shipped APK pointed at a developer's
  /// laptop is an app that simply does not work, and it fails on the customer's
  /// phone rather than on anyone's screen here.
  static const String _productionApiBaseUrl = 'https://homemate-faas.bfast.smartstock.co.tz';

  /// A developer running `flutter run` with no arguments wants their own
  /// backend, and only a debug or profile build can be that.
  static const String _developmentApiBaseUrl = 'http://localhost:3001';

  /// Explicitly supplied by the build, e.g.
  /// `--dart-define=API_BASE_URL=https://staging.homemate.co.tz`. Empty when
  /// nothing was passed, which is how the default below can depend on the
  /// build mode — `String.fromEnvironment`'s own `defaultValue` must be a
  /// compile-time constant and so cannot.
  static const String _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Where the API lives.
  ///
  /// An explicit `--dart-define` always wins, so staging and the CI builds keep
  /// working exactly as before. With nothing passed, the mode decides: release
  /// goes to production, debug and profile to localhost.
  ///
  /// Spelled `== ''` rather than `.isNotEmpty` because this has to stay a
  /// compile-time constant, and a property getter is not one.
  static const String apiBaseUrl = _configuredApiBaseUrl == ''
      ? (kReleaseMode ? _productionApiBaseUrl : _developmentApiBaseUrl)
      : _configuredApiBaseUrl;

  /// True when the app is talking to the deployed backend. The profile screen
  /// shows the environment when it is not, so a tester can never be left
  /// wondering which server they are looking at.
  static bool get isProduction => apiBaseUrl == _productionApiBaseUrl;

  /// OpenStreetMap raster tiles. Overridable so a deployment can point at its
  /// own cache rather than hammering the public one.
  static const String mapTileUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  /// Required by the OSM tile usage policy; a real deployment must set it.
  static const String mapUserAgent = String.fromEnvironment(
    'MAP_USER_AGENT',
    defaultValue: 'tz.co.homemate.app',
  );

  /// Where the map opens before anything is searched: Dar es Salaam.
  ///
  /// Dart has no `double.fromEnvironment`, so these arrive as text and are
  /// parsed once. A malformed override falls back rather than crashing at
  /// launch — a bad coordinate should not stop the app opening.
  static const String _latitude = String.fromEnvironment('DEFAULT_LATITUDE', defaultValue: '-6.7924');
  static const String _longitude = String.fromEnvironment('DEFAULT_LONGITUDE', defaultValue: '39.2083');

  static double get defaultLatitude => double.tryParse(_latitude) ?? -6.7924;
  static double get defaultLongitude => double.tryParse(_longitude) ?? 39.2083;

  static const int requestTimeoutSeconds = int.fromEnvironment(
    'REQUEST_TIMEOUT_SECONDS',
    defaultValue: 20,
  );

  /// Serves the same purpose as a `.env` — a single place to read the config
  /// back — without pretending any of it is private.
  static Map<String, Object> describe() => {
    'apiBaseUrl': apiBaseUrl,
    'isProduction': isProduction,
    'buildMode': kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug'),
    'mapTileUrl': mapTileUrl,
    'defaultLatitude': defaultLatitude,
    'defaultLongitude': defaultLongitude,
    'requestTimeoutSeconds': requestTimeoutSeconds,
  };
}
