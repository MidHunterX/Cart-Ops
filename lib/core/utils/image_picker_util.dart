import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

enum ImagePickerAction { gallery, camera, remove }

class ImagePickerUtil {
  static Future<String?> pickAndSaveImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 60,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${const Uuid().v4()}.jpg';
      final savedImage = await File(pickedFile.path).copy('${directory.path}/$fileName');
      return savedImage.path;
    }
    return null;
  }

  static Future<ImagePickerAction?> showImagePickerOptions(
    BuildContext context,
    bool hasImage,
  ) async {
    return showModalBottomSheet<ImagePickerAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImagePickerAction.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImagePickerAction.camera),
            ),
            if (hasImage)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove Image'),
                onTap: () => Navigator.pop(context, ImagePickerAction.remove),
              ),
          ],
        ),
      ),
    );
  }
}
