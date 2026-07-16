import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopping_assist/core/utils/image_picker_util.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';
import 'package:shopping_assist/core/widgets/app_image_selector.dart';

class AddItemDialog extends StatefulWidget {
  final int? groupId;

  const AddItemDialog({super.key, required this.groupId});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _controller = TextEditingController();
  XFile? _pendingImage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      String? finalPath;
      if (_pendingImage != null) {
        finalPath = await ImagePickerUtil.saveImage(_pendingImage!.path);
      }

      if (mounted) {
        context.read<ItemsRepository>().insertItem(
          name: name,
          groupId: widget.groupId,
          imagePath: finalPath,
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Item'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: 'e.g. Milk, Bread, Tools'),
              autofocus: true,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            AppImageSelector(
              pendingImage: _pendingImage,
              onImagePicked: (file) => setState(() => _pendingImage = file),
              onImageRemoved: () => setState(() => _pendingImage = null),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
