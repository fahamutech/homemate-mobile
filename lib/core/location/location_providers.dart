import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import 'location_service.dart';

/// Where the app stands with the customer's location, and the one place that
/// decides what to do about it.
///
/// The policy is the soft-ask: the app never shows the OS prompt on launch. It
/// renders a card that explains what location buys you, and only an explicit
/// tap calls [enable]. On iOS the system prompt can be shown once and only
/// once, so spending it before the customer has any reason to say yes is
/// spending it badly.
class NearMeState {
  const NearMeState({
    this.availability = LocationAvailability.unknown,
    this.latitude,
    this.longitude,
    this.isBusy = false,
    this.manualPlaceName,
  });

  final LocationAvailability availability;
  final double? latitude;
  final double? longitude;
  final bool isBusy;

  /// An area the customer picked by hand instead. This is the way out of every
  /// refusal: "Near me" still works, it is just near somewhere they chose.
  final String? manualPlaceName;

  bool get hasPosition => latitude != null && longitude != null;
  bool get isGranted => availability == LocationAvailability.granted;
  bool get isManual => manualPlaceName != null;

  /// Whether the section can search around a point at all, however we got it.
  bool get canSearchNearby => hasPosition;

  /// Whether to show the explain-and-ask card above the listings.
  bool get needsPrompt => !hasPosition;

  /// Whether tapping "Use my location" could still change anything, or whether
  /// the customer has to leave the app.
  bool get canAskAgain =>
      availability == LocationAvailability.unknown || availability == LocationAvailability.denied;

  /// The heading on the prompt card. It says what is true, so that the button
  /// underneath it is never a lie.
  String get promptTitle => switch (availability) {
        LocationAvailability.serviceDisabled => 'Location is switched off',
        LocationAvailability.deniedForever => 'Location is blocked for HomeMate',
        LocationAvailability.denied => 'See homes near you',
        _ => 'See homes near you',
      };

  String get promptMessage => switch (availability) {
        LocationAvailability.serviceDisabled =>
          'Turn on location in your device settings and we will sort listings from nearest to furthest.',
        LocationAvailability.deniedForever =>
          'HomeMate cannot ask again from here. Allow location in Settings, or pick an area instead.',
        LocationAvailability.denied =>
          'Allow location and we will sort listings from nearest to furthest.',
        _ => 'Share your location and we will sort listings from nearest to furthest.',
      };

  /// What the primary button says. It matches what will actually happen —
  /// "Allow location" on a permanent refusal would do nothing at all.
  String get promptAction => switch (availability) {
        LocationAvailability.serviceDisabled => 'Open location settings',
        LocationAvailability.deniedForever => 'Open settings',
        _ => 'Use my location',
      };

  NearMeState copyWith({
    LocationAvailability? availability,
    Object? latitude = _unset,
    Object? longitude = _unset,
    bool? isBusy,
    Object? manualPlaceName = _unset,
  }) =>
      NearMeState(
        availability: availability ?? this.availability,
        latitude: latitude == _unset ? this.latitude : latitude as double?,
        longitude: longitude == _unset ? this.longitude : longitude as double?,
        isBusy: isBusy ?? this.isBusy,
        manualPlaceName:
            manualPlaceName == _unset ? this.manualPlaceName : manualPlaceName as String?,
      );

  static const Object _unset = Object();
}

class NearMeNotifier extends StateNotifier<NearMeState> {
  NearMeNotifier(this._service) : super(const NearMeState()) {
    // A silent look, never a prompt: this is what lets the card say "Location
    // is blocked" rather than "See homes near you" on the very first build,
    // for someone who refused three releases ago.
    _refreshQuietly();
  }

  final LocationService _service;

  Future<void> _refreshQuietly() async {
    final availability = await _service.availability();
    if (!mounted) return;
    state = state.copyWith(availability: availability);

    // Already granted from a previous session — use it without asking again.
    if (availability == LocationAvailability.granted) {
      final result = await _service.current();
      if (!mounted) return;
      if (result.hasPosition) {
        state = state.copyWith(
          latitude: result.latitude,
          longitude: result.longitude,
          manualPlaceName: null,
        );
      }
    }
  }

  /// The explicit tap. This is the only path that may show the OS prompt.
  Future<void> enable() async {
    if (state.isBusy) return;
    state = state.copyWith(isBusy: true);
    try {
      // Permission cannot be granted from inside the app any more, so send
      // them where it can — and re-check when they come back.
      if (!state.canAskAgain) {
        await _service.openSettings(
          appSettings: state.availability != LocationAvailability.serviceDisabled,
        );
        final availability = await _service.availability();
        if (!mounted) return;
        state = state.copyWith(availability: availability, isBusy: false);
        if (availability == LocationAvailability.granted) await _refreshQuietly();
        return;
      }

      final result = await _service.request();
      if (!mounted) return;
      state = state.copyWith(
        availability: result.availability,
        latitude: result.hasPosition ? result.latitude : null,
        longitude: result.hasPosition ? result.longitude : null,
        manualPlaceName: result.hasPosition ? null : state.manualPlaceName,
        isBusy: false,
      );
    } catch (_) {
      if (mounted) state = state.copyWith(isBusy: false);
    }
  }

  /// The way round every refusal: search around a place they chose instead.
  void useManualArea({
    required String placeName,
    required double latitude,
    required double longitude,
  }) {
    state = state.copyWith(
      latitude: latitude,
      longitude: longitude,
      manualPlaceName: placeName,
    );
  }

  /// Drop a manually chosen area and fall back to whatever the device allows.
  void clearManualArea() {
    state = state.copyWith(manualPlaceName: null, latitude: null, longitude: null);
    _refreshQuietly();
  }

  /// Re-check after the customer has been to Settings and come back.
  Future<void> recheck() => _refreshQuietly();
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);

final nearMeProvider = StateNotifierProvider<NearMeNotifier, NearMeState>(
  (ref) => NearMeNotifier(ref.watch(locationServiceProvider)),
);

/// Where a map should open when nothing better is known.
///
/// The customer's own position when we have it, the area they picked when they
/// picked one, and the configured city centre otherwise — so a map is never
/// blank and never silently centres on the wrong continent.
final mapFocusProvider = Provider<({double latitude, double longitude, bool isPrecise})>((ref) {
  final nearMe = ref.watch(nearMeProvider);
  if (nearMe.hasPosition) {
    return (latitude: nearMe.latitude!, longitude: nearMe.longitude!, isPrecise: true);
  }
  return (latitude: Env.defaultLatitude, longitude: Env.defaultLongitude, isPrecise: false);
});
