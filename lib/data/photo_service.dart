import 'dart:io';

import 'package:image_picker/image_picker.dart';

/// Gets a photo from the camera or from the gallery. Wrapped in a small class
/// so tests can replace it (there is no camera in a test).
abstract class PhotoService {
  /// Opens the camera. Returns null if the user cancels.
  Future<File?> takePicture();

  /// Opens the gallery. Returns null if the user cancels.
  Future<File?> pickFromGallery();
}

class ImagePickerPhotoService implements PhotoService {
  final _picker = ImagePicker();

  @override
  Future<File?> takePicture() => _pick(ImageSource.camera);

  @override
  Future<File?> pickFromGallery() => _pick(ImageSource.gallery);

  Future<File?> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      // Resizing on the fly keeps the saved files small and the list fast.
      maxWidth: 1200,
      imageQuality: 85,
    );
    return picked == null ? null : File(picked.path);
  }
}
