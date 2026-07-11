import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';
import 'package:shopping_assist/features/purchased_items/repositories/purchased_items_repository.dart';
import 'package:shopping_assist/features/purchased_items/views/widgets/add_item_components/input_field_box.dart';
import 'add_item_components/item_dialogs.dart';
import 'common/purchased_item_form.dart';

class AddPurchasedItemSheet extends StatefulWidget {
  final Purchase purchase;
  final Group? group;

  const AddPurchasedItemSheet({super.key, required this.purchase, required this.group});

  @override
  State<AddPurchasedItemSheet> createState() => _AddPurchasedItemSheetState();
}

class _AddPurchasedItemSheetState extends State<AddPurchasedItemSheet> {
  final GlobalKey<PurchasedItemFormState> _formKey = GlobalKey<PurchasedItemFormState>();

  String _name = '';
  int? _itemId;
  List<Item> _allItems = [];
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

  void _loadLastPurchaseDetails(int itemId) async {
    try {
      final repo = context.read<ItemsRepository>();
      final lastPurchase = await repo.getLastPurchasedDetails(itemId);

      if (lastPurchase != null && mounted) {
        _formKey.currentState?.updateValues(
          price: lastPurchase.price.toString(),
          qty: lastPurchase.isWeight ? '' : '1',
          isWeight: lastPurchase.isWeight,
          discount: lastPurchase.discount > 0 ? lastPurchase.discount.toString() : '',
          activeField: lastPurchase.isWeight ? ActiveField.quantity : ActiveField.price,
        );
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _showNameDialog() {
    ItemDialogs.showNameDialog(
      context: context,
      currentName: _name,
      allItems: _allItems,
      onSave: (newName, itemId) {
        setState(() {
          _name = newName;
          _itemId = itemId;
        });

        if (itemId != null) {
          try {
            final selectedItem = _allItems.firstWhere((item) => item.id == itemId);
            _formKey.currentState?.updateImage(selectedItem.imagePath, changed: false);
          } catch (_) {}
          _loadLastPurchaseDetails(itemId);
        }
      },
    );
  }

  Future<void> _submit(
    double? price,
    double? qty,
    double discount,
    bool isWeight,
    String? imagePath,
    bool imageChanged,
  ) async {
    final name = _name.trim();

    try {
      await context.read<PurchasedItemsRepository>().addPurchasedItem(
        itemId: _itemId,
        name: name,
        price: price,
        qty: qty,
        discount: discount,
        isWeight: isWeight,
        purchaseId: widget.purchase.id,
        group: widget.group,
        imagePath: imageChanged ? drift.Value(imagePath) : const drift.Value.absent(),
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
    return PurchasedItemForm(
      key: _formKey,
      itemId: _itemId,
      title: 'Add an Item',
      itemName: _name,
      isLoading: _isLoading,
      onNameTap: _showNameDialog,
      onSubmit: _submit,
    );
  }
}
