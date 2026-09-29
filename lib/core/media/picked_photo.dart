import 'dart:typed_data';

/// A photo the person chose, before or after it is made upload-ready.
class PickedPhoto {
  const PickedPhoto({required this.bytes, required this.name, required this.contentType});

  final Uint8List bytes;
  final String name;
  final String contentType;
}
