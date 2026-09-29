import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'webp_encoder.dart';

/// The browser's own encoder: draw on a canvas, ask it for WebP.
class PlatformWebpEncoder implements WebpEncoder {
  @override
  Future<Uint8List> encode(Uint8List bytes, {int maxSide = 1600}) async {
    final url = web.URL.createObjectURL(web.Blob([bytes.toJS].toJS));
    try {
      final image = web.HTMLImageElement()..src = url;
      await image.decode().toDart;
      final longest = image.naturalWidth > image.naturalHeight ? image.naturalWidth : image.naturalHeight;
      final scale = longest > maxSide ? maxSide / longest : 1.0;
      final width = (image.naturalWidth * scale).round();
      final height = (image.naturalHeight * scale).round();

      final canvas = web.HTMLCanvasElement()
        ..width = width
        ..height = height;
      canvas.context2D.drawImage(image, 0, 0, width.toDouble(), height.toDouble());

      final done = Completer<web.Blob?>();
      canvas.toBlob(((web.Blob? blob) => done.complete(blob)).toJS, 'image/webp', 0.82.toJS);
      final blob = await done.future;
      if (blob == null) throw StateError('This browser cannot make WebP images');
      final buffer = await blob.arrayBuffer().toDart;
      return buffer.toDart.asUint8List();
    } finally {
      web.URL.revokeObjectURL(url);
    }
  }
}
