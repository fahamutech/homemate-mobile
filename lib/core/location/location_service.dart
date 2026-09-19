import 'package:geolocator/geolocator.dart';

/// Where the customer is, and — more often — why we are not allowed to know.
///
/// The three refusals are deliberately kept apart, because they are three
/// different screens with three different things to do about them:
///
///   - **denied** — they said no once, and we may ask again;
///   - **deniedForever** — the OS will not ask again, so only Settings helps;
///   - **serviceDisabled** — location is switched off device-wide, and no
///     amount of permission will produce a position.
///
/// Collapsing these into one "no location" state is what produces the classic
/// dead end: a button that asks for permission, does nothing, and gives the
/// customer no way forward.
enum LocationAvailability {
  /// Nobody has asked yet. This is the state the soft-ask exists for.
  unknown,
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

/// A position, or the reason there is not one.
class LocationResult {
  const LocationResult({required this.availability, this.latitude, this.longitude});

  const LocationResult.unavailable(this.availability)
      : latitude = null,
        longitude = null;

  final LocationAvailability availability;
  final double? latitude;
  final double? longitude;

  bool get hasPosition => latitude != null && longitude != null;
  bool get isGranted => availability == LocationAvailability.granted;

  /// Whether asking again could plausibly change the answer. `deniedForever`
  /// and `serviceDisabled` both need the customer to leave the app, so the
  /// button must say so rather than silently doing nothing.
  bool get canAskAgain =>
      availability == LocationAvailability.unknown || availability == LocationAvailability.denied;
}

/// The app's one door onto the device's location.
///
/// An interface rather than static calls to `Geolocator`, so the widget tests
/// can drive every one of the refusal states without a device — which is the
/// only way the permission screens get tested at all.
abstract class LocationService {
  /// What we are allowed, without asking for anything. Safe to call on every
  /// build: it never shows a prompt.
  Future<LocationAvailability> availability();

  /// Ask, if asking is still possible, and return a position when we get one.
  /// This is the only method that may show the OS prompt, and it is only ever
  /// called from an explicit tap.
  Future<LocationResult> request();

  /// The current position, assuming permission is already granted.
  Future<LocationResult> current();

  /// Open the OS page where the customer can undo a permanent refusal.
  Future<bool> openSettings({bool appSettings = true});
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  static LocationAvailability _map(LocationPermission permission) => switch (permission) {
        LocationPermission.always || LocationPermission.whileInUse => LocationAvailability.granted,
        LocationPermission.denied => LocationAvailability.denied,
        LocationPermission.deniedForever => LocationAvailability.deniedForever,
        LocationPermission.unableToDetermine => LocationAvailability.unknown,
      };

  @override
  Future<LocationAvailability> availability() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAvailability.serviceDisabled;
    }
    return _map(await Geolocator.checkPermission());
  }

  @override
  Future<LocationResult> request() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationResult.unavailable(LocationAvailability.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final availability = _map(permission);
    if (availability != LocationAvailability.granted) {
      return LocationResult.unavailable(availability);
    }
    return current();
  }

  @override
  Future<LocationResult> current() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          // "Near me" is a neighbourhood question, not a navigation one, and
          // medium accuracy is both faster and kinder to the battery.
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return LocationResult(
        availability: LocationAvailability.granted,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      // A timeout or a hardware refusal is not a permission problem, but from
      // the screen's point of view it is the same dead end — and the customer
      // is offered the same way round it.
      return const LocationResult.unavailable(LocationAvailability.denied);
    }
  }

  @override
  Future<bool> openSettings({bool appSettings = true}) =>
      appSettings ? Geolocator.openAppSettings() : Geolocator.openLocationSettings();
}
