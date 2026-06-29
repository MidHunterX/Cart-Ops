import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/features/purchased_items/repositories/purchased_items_repository.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
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

  String _formatDouble(double val) {
    if (val == val.truncateToDouble()) {
      return val.truncate().toString();
    }
    return val.toString();
  }

  @override
  void initState() {
    super.initState();
    _priceStr = _formatDouble(widget.purchasedItem.price);
    _qtyStr = _formatDouble(widget.purchasedItem.quantity);
    _discountStr = _formatDouble(widget.purchasedItem.discount);
    _isWeight = widget.purchasedItem.isWeight;
    _activeField = widget.initialField;

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
            hasImage: widget.item.imagePath != null,
            discountStr: _discountStr,
            onKeyPressed: _handleKeypadPress,
            onNameTap: () => _showLockedMsg('Item name cannot be edited here.'),
            onImageTap: () => _showLockedMsg('Item image cannot be edited here.'),
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

  Widget _buildHeader() {
    final currencySymbol = context.read<SettingsProvider>().currencySymbol;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Edit Item', style: Theme.of(context).textTheme.titleLarge),
        Row(
          children: [
            Text(
              '$currencySymbol/kg',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: _isWeight,
              onChanged: (val) {
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
          ],
        ),
      ],
    );
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
