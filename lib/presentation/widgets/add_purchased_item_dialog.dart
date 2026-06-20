import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:shopping_assist/database/database.dart';

class AddPurchasedItemDialog extends StatefulWidget {
  final Purchase purchase;
  final Group? group;

  const AddPurchasedItemDialog({
    super.key,
    required this.purchase,
    required this.group,
  });

  @override
  State<AddPurchasedItemDialog> createState() => _AddPurchasedItemDialogState();
}

class _AddPurchasedItemDialogState extends State<AddPurchasedItemDialog> {
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _discountController = TextEditingController(text: '0');
  TextEditingController? _nameController;

  List<Item> _groupItems = [];
  bool _isWeight = false;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  // Pre-load items from the database to drive the autocomplete feature safely
  Future<void> _fetchItems() async {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final items = widget.group == null
        ? await db.itemsDao.getItemsWithoutGroup()
        : await db.itemsDao.getItemsInGroup(widget.group!.id);
    setState(() {
      _groupItems = items;
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _qtyController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _nameController?.text.trim() ?? '';
    final priceStr = _priceController.text.trim();
    final qtyStr = _qtyController.text.trim();
    final discountStr = _discountController.text.trim();

    if (name.isEmpty || priceStr.isEmpty || qtyStr.isEmpty) return;

    final price = double.tryParse(priceStr) ?? 0.0;
    final qty = double.tryParse(qtyStr) ?? 1.0;
    final discount = double.tryParse(discountStr) ?? 0.0;

    final db = Provider.of<AppDatabase>(context, listen: false);

    Item? targetItem;
    try {
      // Find matching item case-insensitively
      targetItem = _groupItems.firstWhere(
        (item) => item.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      targetItem = null;
    }

    int itemId;
    if (targetItem != null) {
      // Reuse existing item ID
      itemId = targetItem.id;
    } else {
      // Create new Item under the group as it didn't match perfectly
      itemId = await db.itemsDao.insertItem(
        ItemsCompanion.insert(
          name: name,
          price: price, // initial base price
          groupId: Value(widget.group?.id),
        ),
      );
    }

    // Record the instance of the Purchase
    await db.purchasedItemsDao.insertPurchasedItem(
      PurchasedItemsCompanion.insert(
        price: price, // Explicit purchase price
        quantity: qty,
        isWeight: Value(_isWeight),
        discount: Value(discount),
        purchaseId: widget.purchase.id,
        itemId: itemId,
      ),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Item to Purchase'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Autocomplete<Item>(
              displayStringForOption: (Item option) => option.name,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<Item>.empty();
                }
                return _groupItems.where((Item option) {
                  return option.name.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  );
                });
              },
              onSelected: (Item selection) {
                // Pre-fill parameters on auto-complete match
                _priceController.text = selection.price.toString();
                _qtyController.text = '1';
              },
              fieldViewBuilder:
                  (
                    context,
                    textEditingController,
                    focusNode,
                    onFieldSubmitted,
                  ) {
                    _nameController =
                        textEditingController; // Attach controller hook to read on Submit
                    return TextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        hintText: 'Search or enter new item',
                      ),
                    );
                  },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _qtyController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _discountController,
              decoration: const InputDecoration(labelText: 'Discount'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Measured by weight?'),
              value: _isWeight,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _isWeight = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
