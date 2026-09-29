import 'dart:typed_data';

import 'webp_encoder_io.dart' if (dart.library.js_interop) 'webp_encoder_web.dart' as platform;

/// Listing photos are stored as WebP (the API refuses anything else), resized
/// so a phone on mobile data can send them.
abstract class WebpEncoder {
  Future<Uint8List> encode(Uint8List bytes, {int maxSide = 1600});

  static WebpEncoder platformDefault() => platform.PlatformWebpEncoder();
}
