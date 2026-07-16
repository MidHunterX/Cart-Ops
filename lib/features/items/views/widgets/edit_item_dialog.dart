import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/utils/image_picker_util.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';
import 'package:shopping_assist/core/widgets/app_image_selector.dart';

class EditItemDialog extends StatefulWidget {
  final Item item;
  const EditItemDialog({super.key, required this.item});

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  late TextEditingController _controller;
  String? _existingImagePath;
  XFile? _pendingImage;
  bool _imageRemoved = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.name);
    _existingImagePath = widget.item.imagePath;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      String? finalPath = _existingImagePath;

      if (_imageRemoved) {
        finalPath = null;
      }

      if (_pendingImage != null) {
        finalPath = await ImagePickerUtil.saveImage(_pendingImage!.path);
      }

      if (mounted) {
        context.read<ItemsRepository>().updateItem(
          widget.item.id,
          name: name,
          imagePath: drift.Value(finalPath),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Item'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _controller, autofocus: true),
            const SizedBox(height: 16),
            AppImageSelector(
              imagePath: _imageRemoved ? null : _existingImagePath,
              pendingImage: _pendingImage,
              onImagePicked: (file) => setState(() {
                _pendingImage = file;
                _imageRemoved = false;
              }),
              onImageRemoved: () => setState(() {
                _pendingImage = null;
                _imageRemoved = true;
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
