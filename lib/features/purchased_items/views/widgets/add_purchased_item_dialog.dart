import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';
import 'package:shopping_assist/features/purchased_items/repositories/purchased_items_repository.dart';

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
  final _nameController = TextEditingController();

  List<Item> _allItems = [];
  bool _isWeight = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<ItemsRepository>();
      final items = widget.group != null
          ? await repo.getItemsInGroup(widget.group!.id)
          : await repo.getItemsWithoutGroup();
      if (mounted) {
        setState(() {
          _allItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading items: $e')));
      }
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _qtyController.dispose();
    _discountController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _nameController.text.trim();
    final priceStr = _priceController.text.trim();
    final qtyStr = _qtyController.text.trim();
    final discountStr = _discountController.text.trim();

    if (name.isEmpty || priceStr.isEmpty || qtyStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final price = double.tryParse(priceStr) ?? 0.0;
    final qty = double.tryParse(qtyStr) ?? 1.0;
    final discount = double.tryParse(discountStr) ?? 0.0;

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price must be greater than 0')),
      );
      return;
    }

    try {
      await context.read<PurchasedItemsRepository>().addPurchasedItem(
        name: name,
        price: price,
        qty: qty,
        discount: discount,
        isWeight: _isWeight,
        purchaseId: widget.purchase.id,
        group: widget.group,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding item: $e')));
      }
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
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            else
              Autocomplete<Item>(
                displayStringForOption: (Item option) => option.name,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<Item>.empty();
                  }
                  final query = textEditingValue.text.toLowerCase();
                  return _allItems.where((Item option) {
                    return option.name.toLowerCase().contains(query);
                  });
                },
                onSelected: (Item selection) {
                  _nameController.text = selection.name;
                  // Optionally load last price
                  _loadLastPrice(selection.id);
                },
                fieldViewBuilder:
                    (
                      context,
                      textEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      // Sync our controller with the autocomplete controller
                      _nameController.text = textEditingController.text;
                      textEditingController.addListener(() {
                        _nameController.text = textEditingController.text;
                      });

                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                          hintText: 'Search or enter new item',
                        ),
                        onSubmitted: (_) => onFieldSubmitted(),
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
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _loadLastPrice(int itemId) async {
    try {
      final repo = context.read<ItemsRepository>();
      final lastPrice = await repo.getLastPurchasedPrice(itemId);
      if (lastPrice != null && mounted) {
        _priceController.text = lastPrice.toString();
      }
    } catch (e) {
      // Silent fail for last price
    }
  }
}
