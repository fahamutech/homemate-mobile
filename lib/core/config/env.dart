/// Everything that differs between a laptop, staging and a shop phone.
///
/// Values arrive as compile-time `--dart-define`s rather than a bundled file:
/// a Flutter web build is downloadable, so anything baked into an asset is
/// public. Defaults point at a local backend so `flutter run` works with no
/// arguments, and nothing here is a secret.
class Env {
  const Env._();

  /// Where the API lives, e.g. `--dart-define=API_BASE_URL=https://api.homemate.co.tz`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3001',
  );

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
    'mapTileUrl': mapTileUrl,
    'defaultLatitude': defaultLatitude,
    'defaultLongitude': defaultLongitude,
    'requestTimeoutSeconds': requestTimeoutSeconds,
  };
}
