import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/utils/number_formatter.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';
import 'package:shopping_assist/features/purchased_items/repositories/purchased_items_repository.dart';
import 'package:shopping_assist/core/utils/image_picker_util.dart';
import 'add_item_components/input_field_box.dart';
import 'add_item_components/add_item_keypad.dart';
import 'add_item_components/item_dialogs.dart';
import 'add_item_utils/keypad_logic.dart';
import 'common/purchased_item_form_header.dart';
import 'common/unit_quantity_selector.dart';

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
  late String _priceStr;
  late String _qtyStr;
  late String _discountStr;
  late bool _isWeight;
  late ActiveField _activeField;

  late TextEditingController _priceController;
  late TextEditingController _qtyController;
  late FocusNode _priceFocusNode;
  late FocusNode _qtyFocusNode;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _priceStr = widget.purchasedItem.price.toPriceString();
    _qtyStr = widget.purchasedItem.quantity.toPriceString();
    _discountStr = widget.purchasedItem.discount.toPriceString();
    _isWeight = widget.purchasedItem.isWeight;
    _activeField = widget.initialField;
    _imagePath = widget.item.imagePath;

    _priceController = TextEditingController(text: _priceStr);
    _qtyController = TextEditingController(text: _qtyStr);
    _priceFocusNode = FocusNode();
    _qtyFocusNode = FocusNode();

    // Automatically focus the requested input field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_activeField == ActiveField.price) {
        _priceFocusNode.requestFocus();
      } else {
        if (_isWeight) {
          _qtyFocusNode.requestFocus();
        } else {
          // If it's a unit item, quantity doesn't have a keypad input, fallback to price
          _activeField = ActiveField.price;
          _priceFocusNode.requestFocus();
        }
      }
    });

    // If edit discount was tapped from the popup menu, open it directly
    if (widget.openDiscountDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final newDiscount = await ItemDialogs.showDiscountDialog(context, _discountStr);
        if (newDiscount != null && mounted) {
          setState(() => _discountStr = newDiscount.isEmpty ? '0' : newDiscount);
        }
      });
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _qtyController.dispose();
    _priceFocusNode.dispose();
    _qtyFocusNode.dispose();
    super.dispose();
  }

  void _handleImagePicker() async {
    final action = await ImagePickerUtil.showImagePickerOptions(context, _imagePath != null);

    if (action == ImagePickerAction.remove) {
      setState(() => _imagePath = null);
      if (mounted) context.read<ItemsRepository>().updateItemImage(widget.item.id, null);
    } else if (action == ImagePickerAction.gallery || action == ImagePickerAction.camera) {
      final source = action == ImagePickerAction.gallery ? ImageSource.gallery : ImageSource.camera;
      final path = await ImagePickerUtil.pickAndSaveImage(source);
      if (path != null) {
        setState(() => _imagePath = path);
        if (mounted) context.read<ItemsRepository>().updateItemImage(widget.item.id, path);
      }
    }
  }

  void _handleKeypadPress(String val) {
    if (val == '=>') {
      setState(() {
        if (_isWeight) {
          _activeField = _activeField == ActiveField.price
              ? ActiveField.quantity
              : ActiveField.price;
        }
        _activeField == ActiveField.price
            ? _priceFocusNode.requestFocus()
            : _qtyFocusNode.requestFocus();
      });
      return;
    }

    final targetController = (_activeField == ActiveField.price)
        ? _priceController
        : _qtyController;

    setState(() {
      KeypadLogic.handleInput(targetController, val);
      _priceStr = _priceController.text;
      _qtyStr = _qtyController.text;
    });
  }

  void _incrementQuantity() {
    setState(() {
      int currentQty = int.tryParse(_qtyStr) ?? 1;
      currentQty++;
      _qtyStr = currentQty.toString();
      _qtyController.text = _qtyStr;
    });
  }

  void _decrementQuantity() {
    setState(() {
      int currentQty = int.tryParse(_qtyStr) ?? 1;
      if (currentQty > 1) {
        currentQty--;
        _qtyStr = currentQty.toString();
        _qtyController.text = _qtyStr;
      }
    });
  }

  void _submit() async {
    final priceStr = _priceStr.trim();
    final qtyStr = _qtyStr.trim();

    if (priceStr.isEmpty || qtyStr.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill in quantity and price')));
      return;
    }

    final pricePerUnit = double.tryParse(priceStr) ?? 0.0;
    final qty = double.tryParse(qtyStr) ?? 1.0;
    final discount = double.tryParse(_discountStr.trim()) ?? 0.0;

    if (pricePerUnit <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Price must be greater than 0')));
      return;
    }

    if (qty <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Quantity must be greater than 0')));
      return;
    }

    if (discount < 0 || discount >= pricePerUnit) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid discount amount')));
      return;
    }

    try {
      await context.read<PurchasedItemsRepository>().updatePurchasedItem(
        id: widget.purchasedItem.id,
        price: pricePerUnit,
        qty: qty,
        discount: discount,
        isWeight: _isWeight,
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

  void _handleDiscountTap() async {
    final newDiscount = await ItemDialogs.showDiscountDialog(context, _discountStr);
    if (newDiscount != null) {
      setState(() => _discountStr = newDiscount.isEmpty ? '0' : newDiscount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PurchasedItemFormHeader(
            title: 'Edit Item',
            isWeight: _isWeight,
            onWeightChanged: (val) {
              setState(() {
                _isWeight = val;
                if (val) {
                  _qtyStr = '';
                  _qtyController.text = '';
                  _activeField = ActiveField.quantity;
                  _qtyFocusNode.requestFocus();
                } else {
                  _qtyStr = '1';
                  _qtyController.text = '1';
                  _activeField = ActiveField.price;
                  _priceFocusNode.requestFocus();
                }
              });
            },
          ),
          const SizedBox(height: 16),
          _buildFieldsRow(),
          const SizedBox(height: 16),
          AddItemKeypad(
            isLoading: false,
            itemName: widget.item.name,
            hasImage: _imagePath != null,
            discountStr: _discountStr,
            onKeyPressed: _handleKeypadPress,
            onNameTap: () => _showLockedMsg('Item name cannot be edited here.'),
            onImageTap: _handleImagePicker,
            onDiscountTap: _handleDiscountTap,
            onSubmit: _submit,
            onIncrement: _incrementQuantity,
            onDecrement: _decrementQuantity,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showLockedMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildFieldsRow() {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: _isWeight
                ? InputFieldBox(
                    label: 'Quantity (kg)',
                    value: _qtyStr,
                    isActive: _activeField == ActiveField.quantity,
                    onTap: () {
                      setState(() => _activeField = ActiveField.quantity);
                      _qtyFocusNode.requestFocus();
                    },
                    controller: _qtyController,
                    focusNode: _qtyFocusNode,
                  )
                : UnitQuantitySelector(
                    quantity: _qtyStr,
                    onIncrement: _incrementQuantity,
                    onDecrement: _decrementQuantity,
                  ),
          ),
          Expanded(
            flex: 10,
            child: InputFieldBox(
              label: 'Price (per unit)',
              value: _priceStr,
              isActive: _activeField == ActiveField.price,
              onTap: () {
                setState(() => _activeField = ActiveField.price);
                _priceFocusNode.requestFocus();
              },
              controller: _priceController,
              focusNode: _priceFocusNode,
            ),
          ),
        ],
      ),
    );
  }
}
