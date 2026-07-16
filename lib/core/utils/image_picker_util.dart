import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImagePickerUtil {
  /// Picks an image and returns the temporary XFile without copying it to app storage.
  static Future<XFile?> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    return await picker.pickImage(
      source: source,
      imageQuality: 60,
      maxWidth: 1024,
      maxHeight: 1024,
    );
  }

  /// Copies the temporary file to the app's document directory for permanent storage.
  static Future<String?> saveImage(String tempPath) async {
    final file = File(tempPath);
    if (!await file.exists()) return null;

    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${const Uuid().v4()}.jpg';
    final savedImage = await file.copy('${directory.path}/$fileName');
    return savedImage.path;
  }
}
