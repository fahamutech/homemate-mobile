import 'routes.dart';

/// The in-app path for a link from outside the app, or null when it is not
/// one the app handles.
///
/// The SMS says `homemate://landlord/confirm/:propertyId`. On some platforms
/// the router is handed the whole URI, on others only its path with the host
/// taken off (`/confirm/:propertyId`), and on the web the plain path.
String? deepLinkLocation(Uri uri) {
  final segments = [
    if (uri.scheme == 'homemate' && uri.host.isNotEmpty) uri.host,
    ...uri.pathSegments.where((segment) => segment.isNotEmpty),
  ];
  final withoutRole = segments.isNotEmpty && segments.first == 'landlord' ? segments.skip(1).toList() : segments;
  if (withoutRole.length == 2 && withoutRole.first == 'confirm') {
    return Routes.landlordConfirm(withoutRole.last);
  }
  return null;
}

/// A deep link opened while signed out, waiting for sign-in to finish.
class PendingDeepLink {
  String? _location;

  void remember(String location) => _location = location;

  String? take() {
    final location = _location;
    _location = null;
    return location;
  }

  /// The link still waiting, without taking it.
  String? get location => _location;

  bool get isWaiting => _location != null;
}
