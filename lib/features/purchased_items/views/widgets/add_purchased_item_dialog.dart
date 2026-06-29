import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';
import 'package:shopping_assist/features/purchased_items/repositories/purchased_items_repository.dart';

import 'add_item_components/input_field_box.dart';
import 'add_item_components/add_item_keypad.dart';
import 'add_item_components/item_dialogs.dart';
import 'add_item_utils/keypad_logic.dart';
import 'add_item_utils/image_picker.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';

class AddPurchasedItemSheet extends StatefulWidget {
  final Purchase purchase;
  final Group? group;

  const AddPurchasedItemSheet({super.key, required this.purchase, required this.group});

  @override
  State<AddPurchasedItemSheet> createState() => _AddPurchasedItemSheetState();
}

class _AddPurchasedItemSheetState extends State<AddPurchasedItemSheet> {
  String _name = '';
  String _priceStr = '';
  String _qtyStr = '1';
  String _discountStr = '0';
  bool _isWeight = false;

  ActiveField _activeField = ActiveField.price;
  List<Item> _allItems = [];
  bool _isLoading = true;
  String? _imagePath;

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
        setState(() {
          _priceStr = lastPurchase.price.toString();
          _isWeight = lastPurchase.isWeight;

          if (_isWeight) {
            _qtyStr = '';
            _activeField = ActiveField.quantity;
          } else {
            _qtyStr = '1';
            _activeField = ActiveField.price;
          }
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _handleImagePicker() async {
    final action = await ItemDialogs.showImagePickerOptions(context, _imagePath != null);

    if (action == ImagePickerAction.remove) {
      setState(() => _imagePath = null);
    } else if (action == ImagePickerAction.gallery || action == ImagePickerAction.camera) {
      final source = action == ImagePickerAction.gallery ? ImageSource.gallery : ImageSource.camera;
      final path = await ImagePickerUtil.pickAndSaveImage(source);
      if (path != null) setState(() => _imagePath = path);
    }
  }

  void _handleKeypadPress(String val) {
    setState(() {
      if (val == '=>') {
        _activeField = _activeField == ActiveField.price ? ActiveField.quantity : ActiveField.price;
        return;
      }

      String current = _activeField == ActiveField.price ? _priceStr : _qtyStr;
      String updated = KeypadLogic.calculateNewValue(current, val);

      if (_activeField == ActiveField.price) {
        _priceStr = updated;
      } else {
        _qtyStr = updated;
      }
    });
  }

  void _submit() async {
    final name = _name.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an item name')));
      _showNameDialog();
      return;
    }

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

    try {
      await context.read<PurchasedItemsRepository>().addPurchasedItem(
        name: name,
        price: pricePerUnit,
        qty: qty,
        discount: discount,
        isWeight: _isWeight,
        purchaseId: widget.purchase.id,
        group: widget.group,
        imagePath: _imagePath,
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

  void _showNameDialog() {
    ItemDialogs.showNameDialog(
      context: context,
      currentName: _name,
      allItems: _allItems,
      onSave: (newName, itemId) {
        setState(() => _name = newName);
        if (itemId != null) _loadLastPurchaseDetails(itemId);
      },
    );
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
            isLoading: _isLoading,
            itemName: _name,
            hasImage: _imagePath != null,
            discountStr: _discountStr,
            onKeyPressed: _handleKeypadPress,
            onNameTap: _showNameDialog,
            onImageTap: _handleImagePicker,
            onDiscountTap: () async {
              final newDiscount = await ItemDialogs.showDiscountDialog(context, _discountStr);
              if (newDiscount != null) {
                setState(() => _discountStr = newDiscount.isEmpty ? '0' : newDiscount);
              }
            },
            onSubmit: _submit,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final currencySymbol = context.read<SettingsProvider>().currencySymbol;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Add an Item', style: Theme.of(context).textTheme.titleLarge),
        Row(
          children: [
            Text(
              '$currencySymbol/kg',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
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
                    _activeField = ActiveField.quantity;
                  } else {
                    _qtyStr = '1';
                    _activeField = ActiveField.price;
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
    return Row(
      children: [
        if (_isWeight)
          InputFieldBox(
            label: 'Quantity (kg)',
            value: _qtyStr,
            isActive: _activeField == ActiveField.quantity,
            flex: 6,
            onTap: () => setState(() => _activeField = ActiveField.quantity),
          )
        else
          InputFieldBox(
            label: 'Quantity',
            value: _qtyStr,
            isActive: _activeField == ActiveField.quantity,
            flex: 6,
            onTap: () => setState(() => _activeField = ActiveField.quantity),
            customContent: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AdjustButton(
                  icon: Icons.remove,
                  onTap: () {
                    double q = double.tryParse(_qtyStr) ?? 1;
                    if (q > 1) {
                      setState(() => _qtyStr = (q - 1).toInt().toString());
                    }
                  },
                ),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _qtyStr.isEmpty ? '0' : _qtyStr,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                AdjustButton(
                  icon: Icons.add,
                  onTap: () {
                    double q = double.tryParse(_qtyStr) ?? 1;
                    setState(() => _qtyStr = (q + 1).toInt().toString());
                  },
                ),
              ],
            ),
          ),
        InputFieldBox(
          label: _isWeight ? 'Price (per kg)' : 'Price (per unit)',
          value: _priceStr,
          isActive: _activeField == ActiveField.price,
          flex: 9,
          onTap: () => setState(() => _activeField = ActiveField.price),
        ),
      ],
    );
  }
}
