import 'package:url_launcher/url_launcher.dart';

/// Phone calls and WhatsApp chats from a partner screen. An interface so the
/// buttons can be tested without leaving the app.
abstract class ContactLauncher {
  Future<bool> call(String phone);
  Future<bool> whatsApp(String phone, {String? message});
}

/// `tel:` and `https://wa.me/<digits>` — the forms both platforms and the web
/// understand.
Uri callUri(String phone) => Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), ''));

Uri whatsAppUri(String phone, {String? message}) => Uri.https(
      'wa.me',
      '/${phone.replaceAll(RegExp(r'[^0-9]'), '')}',
      message == null || message.isEmpty ? null : {'text': message},
    );

class UrlContactLauncher implements ContactLauncher {
  @override
  Future<bool> call(String phone) => launchUrl(callUri(phone));

  @override
  Future<bool> whatsApp(String phone, {String? message}) =>
      launchUrl(whatsAppUri(phone, message: message), mode: LaunchMode.externalApplication);
}
