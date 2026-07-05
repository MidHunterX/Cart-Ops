import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/utils/number_formatter.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';
import 'package:shopping_assist/features/purchased_items/repositories/purchased_items_repository.dart';
import 'package:shopping_assist/features/purchased_items/views/widgets/add_item_components/input_field_box.dart';
import 'common/purchased_item_form.dart';

class EditPurchasedItemSheet extends StatefulWidget {
  final PurchasedItem purchasedItem;
  final Item item;
  final ActiveField initialField;
  final bool openDiscountDialog;

  const EditPurchasedItemSheet({
    super.key,
    required this.purchasedItem,
    required this.item,
    this.initialField = ActiveField.price,
    this.openDiscountDialog = false,
  });

  @override
  State<EditPurchasedItemSheet> createState() => _EditPurchasedItemSheetState();
}

class _EditPurchasedItemSheetState extends State<EditPurchasedItemSheet> {
  void _onImageChanged(String? path) {
    if (widget.item.id != -1) {
      context.read<ItemsRepository>().updateItemImage(widget.item.id, path);
    }
  }

  Future<void> _submit(
    double? price,
    double? qty,
    double discount,
    bool isWeight,
    String? imagePath,
    bool imageChanged,
  ) async {
    try {
      await context.read<PurchasedItemsRepository>().updatePurchasedItem(
        id: widget.purchasedItem.id,
        price: price,
        qty: qty,
        discount: discount,
        isWeight: isWeight,
        imagePath: imageChanged ? drift.Value(imagePath) : const drift.Value.absent(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating item: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PurchasedItemForm(
      title: 'Edit Item',
      itemName: widget.item.name,
      initialPrice: widget.purchasedItem.price?.toPriceString() ?? '',
      initialQty: widget.purchasedItem.quantity?.toPriceString() ?? '',
      initialDiscount: widget.purchasedItem.discount.toPriceString(),
      initialIsWeight: widget.purchasedItem.isWeight,
      initialActiveField: widget.initialField,
      initialImagePath: widget.item.imagePath,
      openDiscountDialog: widget.openDiscountDialog,
      onNameTap: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item name cannot be edited here.'))),
      onImageChanged: _onImageChanged,
      onSubmit: _submit,
    );
  }
}
