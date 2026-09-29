import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'webp_encoder.dart';

class PlatformWebpEncoder implements WebpEncoder {
  @override
  Future<Uint8List> encode(Uint8List bytes, {int maxSide = 1600}) => FlutterImageCompress.compressWithList(
        bytes,
        minWidth: maxSide,
        minHeight: maxSide,
        quality: 82,
        format: CompressFormat.webp,
      );
}
