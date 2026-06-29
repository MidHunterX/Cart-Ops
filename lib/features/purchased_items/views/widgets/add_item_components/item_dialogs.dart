import 'package:flutter/material.dart';
import 'package:shopping_assist/core/database/database.dart';

enum ImagePickerAction { gallery, camera, remove }

class ItemDialogs {
  static Future<void> showNameDialog({
    required BuildContext context,
    required String currentName,
    required List<Item> allItems,
    required void Function(String name, int? itemId) onSave,
  }) async {
    final nameCtrl = TextEditingController(text: currentName);
    int? selectedItemId;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Item Name', style: Theme.of(context).textTheme.titleLarge),
        content: Autocomplete<Item>(
          initialValue: TextEditingValue(text: currentName),
          displayStringForOption: (Item option) => option.name,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<Item>.empty();
            }
            final query = textEditingValue.text.toLowerCase();
            return allItems.where((Item option) => option.name.toLowerCase().contains(query));
          },
          onSelected: (Item selection) {
            nameCtrl.text = selection.name;
            selectedItemId = selection.id;
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            controller.addListener(() => nameCtrl.text = controller.text);
            return TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search or enter new item',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                onSave(nameCtrl.text, selectedItemId);
                Navigator.pop(context);
              },
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              onSave(nameCtrl.text, selectedItemId);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  static Future<String?> showDiscountDialog(BuildContext context, String currentDiscount) async {
    final discCtrl = TextEditingController(text: currentDiscount == '0' ? '' : currentDiscount);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discount', style: Theme.of(context).textTheme.titleLarge),
        content: TextField(
          controller: discCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter discount amount',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => Navigator.pop(context, discCtrl.text),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, discCtrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
