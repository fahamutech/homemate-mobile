import 'package:image_picker/image_picker.dart';

import 'picked_photo.dart';

/// Where photos come from: the camera or the gallery. An interface so the
/// screens that take photos can be tested without a device.
abstract class PhotoSource {
  /// One photo, or null when the person backs out.
  Future<PickedPhoto?> pick({bool camera = false});

  /// Several at once, for a listing's photos.
  Future<List<PickedPhoto>> pickMany();
}

class ImagePickerPhotoSource implements PhotoSource {
  final ImagePicker _picker = ImagePicker();

  Future<PickedPhoto> _read(XFile file) async => PickedPhoto(
        bytes: await file.readAsBytes(),
        name: file.name,
        contentType: file.mimeType ?? 'image/jpeg',
      );

  @override
  Future<PickedPhoto?> pick({bool camera = false}) async {
    final file = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2400,
      imageQuality: 90,
    );
    return file == null ? null : _read(file);
  }

  @override
  Future<List<PickedPhoto>> pickMany() async {
    final files = await _picker.pickMultiImage(maxWidth: 2400, imageQuality: 90);
    return [for (final file in files) await _read(file)];
  }
}
