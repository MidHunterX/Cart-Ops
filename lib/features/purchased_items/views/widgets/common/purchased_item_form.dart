import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/utils/image_picker_util.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';
import 'package:shopping_assist/features/items/views/widgets/item_price_history_chart.dart';
import 'package:shopping_assist/features/purchased_items/utils/keypad_logic.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import '../add_item_components/input_field_box.dart';
import '../add_item_components/add_item_keypad.dart';
import '../add_item_components/item_dialogs.dart';
import 'purchased_item_form_header.dart';
import 'unit_quantity_selector.dart';

class PurchasedItemForm extends StatefulWidget {
  final int? itemId; // for price history graph
  final String title;
  final String itemName;
  final String initialPrice;
  final String initialQty;
  final String initialDiscount;
  final bool initialIsWeight;
  final ActiveField initialActiveField;
  final String? initialImagePath;
  final bool isLoading;
  final bool openDiscountDialog;

  final VoidCallback onNameTap;
  final void Function(String? newImagePath)? onImageChanged;
  final void Function(
    double? price,
    double? qty,
    double discount,
    bool isWeight,
    String? imagePath,
    bool imageChanged,
  )
  onSubmit;

  const PurchasedItemForm({
    super.key,
    this.itemId,
    required this.title,
    required this.itemName,
    this.initialPrice = '',
    this.initialQty = '1',
    this.initialDiscount = '0',
    this.initialIsWeight = false,
    this.initialActiveField = ActiveField.price,
    this.initialImagePath,
    this.isLoading = false,
    this.openDiscountDialog = false,
    required this.onNameTap,
    this.onImageChanged,
    required this.onSubmit,
  });

  @override
  State<PurchasedItemForm> createState() => PurchasedItemFormState();
}

class PurchasedItemFormState extends State<PurchasedItemForm> {
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
  bool _imageChanged = false;

  Future<List<PurchasedItemWithPurchase>>? _historyFuture;

  @override
  void initState() {
    super.initState();
    _priceStr = widget.initialPrice;
    _qtyStr = widget.initialQty;
    _discountStr = widget.initialDiscount;
    _isWeight = widget.initialIsWeight;
    _activeField = widget.initialActiveField;
    _imagePath = widget.initialImagePath;

    _priceController = TextEditingController(text: _priceStr);
    _qtyController = TextEditingController(text: _qtyStr);
    _priceFocusNode = FocusNode();
    _qtyFocusNode = FocusNode();

    _fetchHistory();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusActiveField();
      if (widget.openDiscountDialog) {
        _handleDiscountTap();
      }
    });
  }

  // hook to update history chart when item changes
  @override
  void didUpdateWidget(PurchasedItemForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemId != widget.itemId) {
      _fetchHistory();
    }
  }

  void _fetchHistory() {
    if (widget.itemId != null && widget.itemId != -1) {
      _historyFuture = context.read<ItemsRepository>().getPurchaseHistoryForItem(widget.itemId!);
    } else {
      _historyFuture = null;
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

  void _focusActiveField() {
    final controller = (_activeField == ActiveField.price) ? _priceController : _qtyController;
    final node = (_activeField == ActiveField.price) ? _priceFocusNode : _qtyFocusNode;
    node.requestFocus();
    // Select all text so the next keypad press replaces it
    if (controller.text.isNotEmpty) {
      controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
    }
  }

  /// Exposed method for parent widgets to dynamically update form values
  void updateValues({String? price, String? qty, bool? isWeight, ActiveField? activeField}) {
    setState(() {
      if (price != null) {
        _priceStr = price;
        _priceController.text = price;
      }
      if (qty != null) {
        _qtyStr = qty;
        _qtyController.text = qty;
      }
      if (isWeight != null) _isWeight = isWeight;
      if (activeField != null) {
        _activeField = activeField;
        _focusActiveField();
      }
    });
  }

  /// Exposed method for parent widgets to update the image without marking it as "changed" internally
  void updateImage(String? path, {bool changed = false}) {
    setState(() {
      _imagePath = path;
      _imageChanged = changed;
    });
  }

  void _handleWeightToggle(bool val) {
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
  }

  void _handleImagePicker() async {
    final action = await ImagePickerUtil.showImagePickerOptions(context, _imagePath != null);

    if (action == ImagePickerAction.remove) {
      setState(() {
        _imagePath = null;
        _imageChanged = true;
      });
      widget.onImageChanged?.call(null);
    } else if (action == ImagePickerAction.gallery || action == ImagePickerAction.camera) {
      final source = action == ImagePickerAction.gallery ? ImageSource.gallery : ImageSource.camera;
      final path = await ImagePickerUtil.pickAndSaveImage(source);
      if (path != null) {
        setState(() {
          _imagePath = path;
          _imageChanged = true;
        });
        widget.onImageChanged?.call(path);
      }
    }
  }

  void _handleKeypadPress(String val) {
    if (val == '=>') {
      setState(() {
        _activeField = _activeField == ActiveField.price ? ActiveField.quantity : ActiveField.price;
        _focusActiveField();
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

  void _handleDiscountTap() async {
    final newDiscount = await ItemDialogs.showDiscountDialog(context, _discountStr);
    if (newDiscount != null && mounted) {
      setState(() => _discountStr = newDiscount.isEmpty ? '0' : newDiscount);
    }
  }

  void _submit() {
    final priceStr = _priceStr.trim();
    final qtyStr = _qtyStr.trim();

    final pricePerUnit = priceStr.isEmpty ? null : double.tryParse(priceStr);
    final qty = qtyStr.isEmpty ? null : double.tryParse(qtyStr);
    final discount = double.tryParse(_discountStr.trim()) ?? 0.0;

    if (pricePerUnit != null && pricePerUnit <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Price must be greater than 0')));
      return;
    }

    if (qty != null && qty <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Quantity must be greater than 0')));
      return;
    }

    if (pricePerUnit != null && (discount < 0 || discount >= pricePerUnit)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid discount amount')));
      return;
    }

    widget.onSubmit(pricePerUnit, qty, discount, _isWeight, _imagePath, _imageChanged);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: PurchasedItemFormHeader(
              title: widget.title,
              isWeight: _isWeight,
              onWeightChanged: _handleWeightToggle,
            ),
          ),
          const SizedBox(height: 16),

          // CHART INTEGRATION
          if (_historyFuture != null)
            FutureBuilder<List<PurchasedItemWithPurchase>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.length >= 2) {
                  // TODO: Change dynamically based on viewport and datapoint string length
                  final int maxDataPoints = 7;
                  final displayHistory = snapshot.data?.take(maxDataPoints).toList();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0, left: 12, right: 12),
                    child: ItemPriceHistoryChart(
                      history: displayHistory ?? [],
                      isMinimal: true, // Only show a minimal trendline
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

          _buildFieldsRow(settings.weightUnit),
          const SizedBox(height: 16),
          AddItemKeypad(
            isLoading: widget.isLoading,
            itemName: widget.itemName,
            imagePath: _imagePath,
            discountStr: _discountStr,
            isTeleKeypad: settings.isTelephoneLayout,
            onKeyPressed: _handleKeypadPress,
            onNameTap: widget.onNameTap,
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

  Widget _buildFieldsRow(String weightUnit) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: _isWeight
                ? InputFieldBox(
                    label: 'Quantity ($weightUnit)',
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
                    controller: _qtyController,
                    focusNode: _qtyFocusNode,
                    isActive: _activeField == ActiveField.quantity,
                    onTap: () {
                      setState(() => _activeField = ActiveField.quantity);
                      _qtyFocusNode.requestFocus();
                    },
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
