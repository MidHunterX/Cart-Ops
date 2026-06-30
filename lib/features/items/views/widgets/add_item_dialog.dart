import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class AddItemDialog extends StatefulWidget {
  final int? groupId;

  const AddItemDialog({super.key, required this.groupId});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _controller = TextEditingController();
  String? _imagePath;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70, // Compresses the image natively
    );

    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${const Uuid().v4()}.jpg';
      final savedImage = await File(pickedFile.path).copy('${directory.path}/$fileName');

      setState(() {
        _imagePath = savedImage.path;
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      context.read<ItemsRepository>().insertItem(
        name: name,
        groupId: widget.groupId,
        imagePath: _imagePath,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'e.g. Milk, Bread, Tools'),
            autofocus: true,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          if (_imagePath != null)
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_imagePath!),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() => _imagePath = null),
                    ),
                  ),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: _showImagePickerOptions,
              icon: const Icon(Icons.image),
              label: const Text('Add Image'),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
