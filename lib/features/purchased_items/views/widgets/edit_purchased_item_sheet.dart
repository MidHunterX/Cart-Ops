import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/features/purchased_items/repositories/purchased_items_repository.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import 'add_item_components/input_field_box.dart';
import 'add_item_components/add_item_keypad.dart';
import 'add_item_components/item_dialogs.dart';
import 'add_item_utils/keypad_logic.dart';

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
          _buildHeader(),
          const SizedBox(height: 16),
          _buildFieldsRow(),
          const SizedBox(height: 16),
          AddItemKeypad(
            isLoading: false,
            itemName: widget.item.name,
            hasImage: widget.item.imagePath != null,
            discountStr: _discountStr,
            onKeyPressed: _handleKeypadPress,
            onNameTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Item name cannot be edited here.')));
            },
            onImageTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Item image cannot be edited here.')));
            },
            onDiscountTap: () async {
              final newDiscount = await ItemDialogs.showDiscountDialog(context, _discountStr);
              if (newDiscount != null) {
                setState(() => _discountStr = newDiscount.isEmpty ? '0' : newDiscount);
              }
            },
            onSubmit: _submit,
            onIncrement: _incrementQuantity,
            onDecrement: _decrementQuantity,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
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
                : _buildUnitQuantityDisplay(),
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

  Widget _buildUnitQuantityDisplay() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: _decrementQuantity,
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.secondaryContainer,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                padding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  _qtyStr,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _incrementQuantity,
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.secondaryContainer,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
