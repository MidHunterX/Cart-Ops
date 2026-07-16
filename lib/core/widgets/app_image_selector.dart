import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopping_assist/core/utils/image_picker_util.dart';

class AppImageSelector extends StatefulWidget {
  final String? imagePath;
  final XFile? pendingImage;
  final ValueChanged<XFile?> onImagePicked;
  final VoidCallback onImageRemoved;

  const AppImageSelector({
    super.key,
    this.imagePath,
    this.pendingImage,
    required this.onImagePicked,
    required this.onImageRemoved,
  });

  @override
  State<AppImageSelector> createState() => _AppImageSelectorState();
}

class _AppImageSelectorState extends State<AppImageSelector> {
  bool _showDeleteOverlay = false;

  void _handlePick(ImageSource source) async {
    final file = await ImagePickerUtil.pickImage(source);
    if (file != null) {
      setState(() => _showDeleteOverlay = false);
      widget.onImagePicked(file);
    }
  }

  void _handleImageTap() {
    if (_showDeleteOverlay) {
      setState(() => _showDeleteOverlay = false);
      widget.onImageRemoved();
    } else {
      setState(() => _showDeleteOverlay = true);
      // Auto-hide the delete prompt after 3 seconds for cleaner UX
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showDeleteOverlay) {
          setState(() => _showDeleteOverlay = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imagePath != null || widget.pendingImage != null;

    if (hasImage) {
      final imageFile = widget.pendingImage != null
          ? File(widget.pendingImage!.path)
          : File(widget.imagePath!);

      return GestureDetector(
        onTap: _handleImageTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                imageFile,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 120,
                  child: Center(child: Icon(Icons.image_not_supported, size: 40)),
                ),
              ),
            ),
            if (_showDeleteOverlay)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.delete_outline, color: Colors.white, size: 40),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handlePick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handlePick(ImageSource.camera),
            icon: const Icon(Icons.photo_camera),
            label: const Text('Camera'),
          ),
        ),
      ],
    );
  }
}
