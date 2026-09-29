import 'package:url_launcher/url_launcher.dart';

/// Opens a document (a lease PDF) outside the app. An interface so the button
/// can be tested without leaving it.
abstract class LinkOpener {
  Future<bool> open(Uri uri);
}

/// Where a stored document link leads: an http(s) link as it is, an API path
/// joined to [apiBaseUrl]. Anything else — blank, relative, `javascript:`,
/// `file:` — is refused, so a bad value in the database can never be run.
Uri? documentUri(String? url, {required String apiBaseUrl}) {
  final value = (url ?? '').trim();
  if (value.isEmpty) return null;
  if (value.startsWith('/')) {
    final base = apiBaseUrl.endsWith('/') ? apiBaseUrl.substring(0, apiBaseUrl.length - 1) : apiBaseUrl;
    return Uri.tryParse('$base$value');
  }
  final uri = Uri.tryParse(value);
  if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http') || uri.host.isEmpty) return null;
  return uri;
}

class UrlLinkOpener implements LinkOpener {
  @override
  Future<bool> open(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
}
