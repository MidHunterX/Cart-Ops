import 'package:flutter/material.dart';
import 'package:shopping_assist/core/database/database.dart';

class ItemNameDialog {
  static Future<void> show({
    required BuildContext context,
    required String currentName,
    required List<Item> allItems,
    required void Function(String name, int? itemId) onSave,
  }) async {
    final nameCtrl = TextEditingController(text: currentName);
    int? selectedItemId;

    await showDialog(
      context: context,
      builder: (context) => GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: AlertDialog(
          title: Text('Item Name', style: Theme.of(context).textTheme.titleLarge),
          content: Autocomplete<Item>(
            initialValue: TextEditingValue(text: currentName),
            displayStringForOption: (Item option) => option.name,
            optionsViewOpenDirection: OptionsViewOpenDirection.down,
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
      ),
    );
  }
}
