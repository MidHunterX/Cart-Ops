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
  bool _isFieldSelected = false;

  ActiveField _activeField = ActiveField.price;
  List<Item> _allItems = [];
  bool _isLoading = true;
  String? _imagePath;

  // Controllers for input fields
  late TextEditingController _priceController;
  late TextEditingController _qtyController;
  late FocusNode _priceFocusNode;
  late FocusNode _qtyFocusNode;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: _priceStr);
    _qtyController = TextEditingController(text: _qtyStr);
    _priceFocusNode = FocusNode();
    _qtyFocusNode = FocusNode();
    _fetchItems();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _qtyController.dispose();
    _priceFocusNode.dispose();
    _qtyFocusNode.dispose();
    super.dispose();
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
          _priceController.text = _priceStr;
          _isWeight = lastPurchase.isWeight;

          if (_isWeight) {
            _qtyStr = '';
            _qtyController.text = '';
            _activeField = ActiveField.quantity;
          } else {
            _qtyStr = '1';
            _qtyController.text = '1';
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
        Text('Add an Item', style: Theme.of(context).textTheme.titleLarge),
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
                  } else {
                    _qtyStr = '1';
                    _qtyController.text = '1';
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
