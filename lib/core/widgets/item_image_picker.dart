import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopping_assist/core/utils/image_picker_util.dart';
import 'package:shopping_assist/core/widgets/item_image_view.dart';

class ItemImagePicker extends StatelessWidget {
  final String? imagePath;
  final ValueChanged<String?> onChanged;

  const ItemImagePicker({super.key, required this.imagePath, required this.onChanged});

  Future<void> _handleImageTap(BuildContext context) async {
    final action = await ImagePickerUtil.showImagePickerOptions(context, imagePath != null);

    if (action == ImagePickerAction.remove) {
      onChanged(null);
    } else if (action == ImagePickerAction.gallery || action == ImagePickerAction.camera) {
      final source = action == ImagePickerAction.gallery ? ImageSource.gallery : ImageSource.camera;
      final path = await ImagePickerUtil.pickAndSaveImage(source);
      if (path != null) onChanged(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (imagePath != null) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          ItemImageView(
            imagePath: imagePath,
            height: 120,
            width: double.maxFinite,
            borderRadius: BorderRadius.circular(8),
            placeholderIcon: Icons.image_not_supported,
            placeholderIconSize: 40,
          ),
          Positioned(
            top: 4,
            right: 4,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black54,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, size: 16, color: Colors.white),
                onPressed: () => onChanged(null),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.maxFinite,
      child: OutlinedButton.icon(
        onPressed: () => _handleImageTap(context),
        icon: const Icon(Icons.image),
        label: const Text('Add Image'),
      ),
    );
  }
}
