import '../../core/i18n/app_text.dart';

/// The name of a property type or amenity in the reader's language.
///
/// The server's reference data is named in English. The app knows the seeded
/// items by [code] (or, where a payload carries only the name, by that English
/// name); anything added on the server later keeps the [name] it was given.
String referenceName(AppText text, {String? code, required String name}) =>
    (code == null ? null : text.reference(code)) ?? text.referenceNamed(name) ?? name;
