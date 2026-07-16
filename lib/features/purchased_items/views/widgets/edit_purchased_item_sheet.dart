import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/utils/image_picker_util.dart';
import 'package:shopping_assist/core/utils/number_formatter.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';
import 'package:shopping_assist/features/purchased_items/repositories/purchased_items_repository.dart';
import 'package:shopping_assist/features/purchased_items/views/widgets/add_item_components/input_field_box.dart';
import 'add_item_components/item_dialogs.dart';
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
  final GlobalKey<PurchasedItemFormState> _formKey = GlobalKey<PurchasedItemFormState>();

  late String _name;
  late int? _itemId;
  List<Item> _allItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _name = widget.item.name.isEmpty ? (widget.purchasedItem.name ?? '') : widget.item.name;
    _itemId = widget.item.id == -1 ? widget.purchasedItem.itemId : widget.item.id;
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<ItemsRepository>();
      final items = widget.item.groupId != null
          ? await repo.getItemsInGroup(widget.item.groupId!)
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
          price: lastPurchase.price?.toPriceString() ?? '',
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

  void _onImageChanged(String? path) {
    if (_itemId != null && _itemId != -1) {
      context.read<ItemsRepository>().updateItemImage(_itemId!, path);
    }
  }

  Future<void> _submit(
    double? price,
    double? qty,
    double discount,
    bool isWeight,
    XFile? pendingImage,
    bool imageRemoved,
  ) async {
    try {
      String? finalImagePath = widget.item.imagePath;
      bool imageChanged = false;

      if (pendingImage != null) {
        finalImagePath = await ImagePickerUtil.saveImage(pendingImage.path);
        imageChanged = true;
      } else if (imageRemoved) {
        finalImagePath = null;
        imageChanged = true;
      }

      if (mounted) {
        await context.read<PurchasedItemsRepository>().updatePurchasedItem(
          id: widget.purchasedItem.id,
          itemId: _itemId,
          name: _name,
          price: price,
          qty: qty,
          discount: discount,
          isWeight: isWeight,
          groupId: widget.item.groupId,
          imagePath: imageChanged ? drift.Value(finalImagePath) : const drift.Value.absent(),
        );
      }
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
      key: _formKey,
      itemId: _itemId,
      title: 'Edit Item',
      itemName: _name,
      initialPrice: widget.purchasedItem.price?.toPriceString() ?? '',
      initialQty: widget.purchasedItem.quantity?.toPriceString() ?? '',
      initialDiscount: widget.purchasedItem.discount.toPriceString(),
      initialIsWeight: widget.purchasedItem.isWeight,
      initialActiveField: widget.initialField,
      initialImagePath: widget.item.imagePath,
      openDiscountDialog: widget.openDiscountDialog,
      isLoading: _isLoading,
      onNameTap: _showNameDialog,
      onSubmit: _submit,
    );
  }
}
