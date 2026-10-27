import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as syspaths;

/// Keeps the photos of the saved places.
///
/// The camera saves a picture in a *temporary* folder that the system may clean
/// at any time. So when a place is saved, the photo is copied into the app's
/// own documents folder (it stays there until the app is uninstalled) and the
/// database stores only that path.
abstract class ImageStore {
  /// Copies [image] into permanent storage and returns the new file.
  Future<File> save(File image);

  /// Deletes a stored photo (when its place is removed for good).
  Future<void> delete(File image);
}

class LocalImageStore implements ImageStore {
  @override
  Future<File> save(File image) async {
    // `path_provider` asks the OS where this app may keep its files;
    // `path` builds file paths that work on every platform.
    final appDir = await syspaths.getApplicationDocumentsDirectory();
    final extension = path.extension(image.path);
    // A unique name, so two photos called "image.jpg" never overwrite each other.
    final filename = 'place_${DateTime.now().microsecondsSinceEpoch}$extension';
    return image.copy(path.join(appDir.path, filename));
  }

  @override
  Future<void> delete(File image) async {
    try {
      if (await image.exists()) await image.delete();
    } catch (_) {
      // A photo that cannot be deleted is not worth failing the whole action.
    }
  }
}
