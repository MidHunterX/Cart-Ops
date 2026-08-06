import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/utils/number_formatter.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';
import 'package:shopping_assist/features/items/views/widgets/item_price_history_chart.dart';
import 'package:shopping_assist/features/purchased_items/utils/keypad_logic.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import '../form_components/input_field_box.dart';
import '../form_components/item_form_keypad.dart';
import '../form_components/unit_price_calculator_dialog.dart';
import '../form_components/discount_calculator_dialog.dart';
import 'purchased_item_form_header.dart';

class PurchasedItemForm extends StatefulWidget {
  final int? itemId;
  final String title;
  final String itemName;
  final String initialPrice;
  final String initialQty;
  final String initialPackQty;
  final String initialDiscount;
  final bool initialIsWeight;
  final bool initialHasPack;
  final ActiveField initialActiveField;
  final String? initialImagePath;
  final bool isLoading;
  final bool openDiscountDialog;

  final VoidCallback onNameTap;
  final void Function(
    double? price,
    double? qty,
    double? packQty,
    double discount,
    bool isWeight,
    XFile? pendingImage,
    bool imageRemoved,
  )
  onSubmit;

  const PurchasedItemForm({
    super.key,
    this.itemId,
    required this.title,
    required this.itemName,
    this.initialPrice = '',
    this.initialQty = '1',
    this.initialPackQty = '',
    this.initialDiscount = '0',
    this.initialIsWeight = false,
    this.initialHasPack = false,
    this.initialActiveField = ActiveField.price,
    this.initialImagePath,
    this.isLoading = false,
    this.openDiscountDialog = false,
    required this.onNameTap,
    required this.onSubmit,
  });

  @override
  State<PurchasedItemForm> createState() => PurchasedItemFormState();
}

class PurchasedItemFormState extends State<PurchasedItemForm> {
  late String _priceStr;
  late String _qtyStr;
  late String _packQtyStr;
  late String _discountStr;
  late String _totalStr;
  late bool _isWeight;
  late bool _hasPack;
  late ActiveField _activeField;

  late TextEditingController _priceController;
  late TextEditingController _qtyController;
  late TextEditingController _packQtyController;
  late TextEditingController _totalController;
  late FocusNode _priceFocusNode;
  late FocusNode _qtyFocusNode;
  late FocusNode _packQtyFocusNode;
  late FocusNode _totalFocusNode;

  String? _imagePath;
  XFile? _pendingImage;
  bool _imageRemoved = false;

  Future<List<PurchasedItemWithPurchase>>? _historyFuture;

  @override
  void initState() {
    super.initState();
    _priceStr = widget.initialPrice;
    _qtyStr = widget.initialQty;
    _packQtyStr = widget.initialPackQty;
    _discountStr = widget.initialDiscount;
    _isWeight = widget.initialIsWeight;
    _hasPack = widget.initialHasPack;
    _activeField = widget.initialActiveField;
    _imagePath = widget.initialImagePath;

    final double p = double.tryParse(_priceStr) ?? 0.0;
    final double q = double.tryParse(_qtyStr) ?? 0.0;
    final double packQ = _hasPack ? (double.tryParse(_packQtyStr) ?? 1.0) : 1.0;
    if (p > 0 && q > 0) {
      _totalStr = (p * q * packQ).toInputString();
    } else {
      _totalStr = _priceStr;
    }

    _priceController = TextEditingController(text: _priceStr);
    _qtyController = TextEditingController(text: _qtyStr);
    _packQtyController = TextEditingController(text: _packQtyStr);
    _totalController = TextEditingController(text: _totalStr);
    _priceFocusNode = FocusNode();
    _qtyFocusNode = FocusNode();
    _packQtyFocusNode = FocusNode();
    _totalFocusNode = FocusNode();

    _fetchHistory();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusActiveField();
      if (widget.openDiscountDialog) {
        _handleDiscountTap();
      }
    });
  }

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
    _packQtyController.dispose();
    _totalController.dispose();
    _priceFocusNode.dispose();
    _qtyFocusNode.dispose();
    _packQtyFocusNode.dispose();
    _totalFocusNode.dispose();
    super.dispose();
  }

  void _focusActiveField() {
    final controller = switch (_activeField) {
      ActiveField.price => _priceController,
      ActiveField.quantity => _qtyController,
      ActiveField.packQuantity => _packQtyController,
      ActiveField.total => _totalController,
    };
    final node = switch (_activeField) {
      ActiveField.price => _priceFocusNode,
      ActiveField.quantity => _qtyFocusNode,
      ActiveField.packQuantity => _packQtyFocusNode,
      ActiveField.total => _totalFocusNode,
    };
    node.requestFocus();
    if (controller.text.isNotEmpty) {
      controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
    }
  }

  void updateValues({
    String? price,
    String? qty,
    String? packQty,
    bool? isWeight,
    bool? isDual,
    bool? hasPack,
    String? discount,
    ActiveField? activeField,
  }) {
    setState(() {
      if (price != null) {
        _priceStr = price;
        _priceController.text = price;
      }
      if (qty != null) {
        _qtyStr = qty;
        _qtyController.text = qty;
      }
      if (packQty != null) {
        _packQtyStr = packQty;
        _packQtyController.text = packQty;
      }
      if (isWeight != null) _isWeight = isWeight;
      if (hasPack != null) {
        _hasPack = hasPack;
      } else if (isDual != null) {
        _hasPack = isDual;
      }
      if (price != null || qty != null || packQty != null) {
        final double p = double.tryParse(_priceStr) ?? 0.0;
        final double q = double.tryParse(_qtyStr) ?? 0.0;
        final double packQ = _hasPack ? (double.tryParse(_packQtyStr) ?? 1.0) : 1.0;
        if (p > 0 && q > 0) {
          _totalStr = (p * q * packQ).toInputString();
        } else {
          _totalStr = _priceStr;
        }
        _totalController.text = _totalStr;
      }
      if (discount != null) _discountStr = discount;
      if (activeField != null) {
        _activeField = activeField;
        _focusActiveField();
      }
    });
  }

  void updateImage(String? path, {bool changed = false}) {
    setState(() {
      _imagePath = path;
      _pendingImage = null;
      _imageRemoved = false;
    });
  }

  void _handleWeightToggle(bool currentIsWeight) {
    setState(() {
      if (_hasPack) {
        _hasPack = false;
        _packQtyStr = '';
        _packQtyController.text = '';
      } else {
        _isWeight = !currentIsWeight;
        if (_isWeight) {
          _qtyStr = '';
          _qtyController.text = '';
          _activeField = ActiveField.quantity;
        } else {
          _qtyStr = '1';
          _qtyController.text = '1';
          _activeField = ActiveField.price;
        }
      }

      final double price = double.tryParse(_priceStr) ?? 0.0;
      final double qty = double.tryParse(_qtyStr) ?? 0.0;
      if (price > 0 && qty > 0) {
        _totalStr = (price * qty).toInputString();
        _totalController.text = _totalStr;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusActiveField();
    });
  }

  void _handlePackToggle() {
    setState(() {
      if (_hasPack) {
        _hasPack = false;
        _packQtyStr = '';
        _packQtyController.text = '';
        _activeField = _isWeight ? ActiveField.quantity : ActiveField.price;
      } else {
        _hasPack = true;
        if (_packQtyStr.isEmpty) {
          _packQtyStr = '1';
          _packQtyController.text = '1';
        }
        if (_qtyStr.isEmpty && !_isWeight) {
          _qtyStr = '1';
          _qtyController.text = '1';
        }
        _activeField = ActiveField.packQuantity;
      }

      final double price = double.tryParse(_priceStr) ?? 0.0;
      final double qty = double.tryParse(_qtyStr) ?? 0.0;
      final double packQ = _hasPack ? (double.tryParse(_packQtyStr) ?? 1.0) : 1.0;
      if (price > 0 && qty > 0) {
        _totalStr = (price * qty * packQ).toInputString();
        _totalController.text = _totalStr;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusActiveField();
    });
  }

  void _handleKeypadPress(String val) {
    if (val == '=>') {
      final isCompact = context.settingsRead.compactItemList;
      setState(() {
        if (_hasPack) {
          if (isCompact) {
            _activeField = switch (_activeField) {
              ActiveField.packQuantity => ActiveField.quantity,
              ActiveField.quantity => ActiveField.price,
              _ => ActiveField.packQuantity,
            };
          } else {
            _activeField = switch (_activeField) {
              ActiveField.packQuantity => ActiveField.quantity,
              ActiveField.quantity => ActiveField.price,
              ActiveField.price => ActiveField.total,
              ActiveField.total => ActiveField.packQuantity,
            };
          }
        } else {
          if (isCompact) {
            _activeField = _activeField == ActiveField.price
                ? ActiveField.quantity
                : ActiveField.price;
          } else {
            if (_activeField == ActiveField.price) {
              _activeField = ActiveField.total;
            } else if (_activeField == ActiveField.total) {
              _activeField = ActiveField.quantity;
            } else {
              _activeField = ActiveField.price;
            }
          }
        }
        _focusActiveField();
      });
      return;
    }

    final targetController = switch (_activeField) {
      ActiveField.price => _priceController,
      ActiveField.quantity => _qtyController,
      ActiveField.packQuantity => _packQtyController,
      ActiveField.total => _totalController,
    };

    setState(() {
      KeypadLogic.handleInput(targetController, val);
      _priceStr = _priceController.text;
      _qtyStr = _qtyController.text;
      _packQtyStr = _packQtyController.text;
      _totalStr = _totalController.text;

      final double price = double.tryParse(_priceStr) ?? 0.0;
      final double qty = double.tryParse(_qtyStr) ?? 0.0;
      final double packQty = _hasPack ? (double.tryParse(_packQtyStr) ?? 1.0) : 1.0;
      final double effectiveQty = qty * packQty;

      if (_activeField == ActiveField.total) {
        final double total = double.tryParse(_totalStr) ?? 0.0;
        if (total > 0 && effectiveQty > 0) {
          _priceStr = (total / effectiveQty).toInputString();
          _priceController.text = _priceStr;
        } else if (total > 0 && effectiveQty == 0) {
          _priceStr = _totalStr;
          _priceController.text = _priceStr;
        } else if (total == 0) {
          _priceStr = '';
          _priceController.text = '';
        }
      } else {
        if (price > 0 && effectiveQty > 0) {
          _totalStr = (price * effectiveQty).toInputString();
          _totalController.text = _totalStr;
        } else if (price > 0 && effectiveQty == 0) {
          _totalStr = _priceStr;
          _totalController.text = _totalStr;
        } else if (price == 0) {
          _totalStr = '';
          _totalController.text = '';
        }
      }
    });
  }

  void _incrementQuantity() {
    setState(() {
      if (_hasPack || _activeField == ActiveField.packQuantity) {
        int currentQty = double.tryParse(_packQtyStr)?.toInt() ?? 1;
        currentQty++;
        _packQtyStr = currentQty.toString();
        _packQtyController.text = _packQtyStr;
        _activeField = ActiveField.packQuantity;
      } else {
        int currentQty = double.tryParse(_qtyStr)?.toInt() ?? 1;
        currentQty++;
        _qtyStr = currentQty.toString();
        _qtyController.text = _qtyStr;

        final double price = double.tryParse(_priceStr) ?? 0.0;
        final double qty = double.tryParse(_qtyStr) ?? 0.0;
        if (price > 0 && qty > 0) {
          _totalStr = (price * qty).toInputString();
          _totalController.text = _totalStr;
        }
        _activeField = ActiveField.quantity;
      }
      _focusActiveField();
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (_hasPack || _activeField == ActiveField.packQuantity) {
        int currentQty = double.tryParse(_packQtyStr)?.toInt() ?? 1;
        if (currentQty > 1) {
          currentQty--;
          _packQtyStr = currentQty.toString();
          _packQtyController.text = _packQtyStr;
        }
        _activeField = ActiveField.packQuantity;
      } else {
        int currentQty = double.tryParse(_qtyStr)?.toInt() ?? 1;
        if (currentQty > 1) {
          currentQty--;
          _qtyStr = currentQty.toString();
          _qtyController.text = _qtyStr;

          final double price = double.tryParse(_priceStr) ?? 0.0;
          final double qty = double.tryParse(_qtyStr) ?? 0.0;
          if (price > 0 && qty > 0) {
            _totalStr = (price * qty).toInputString();
            _totalController.text = _totalStr;
          }
        }
        _activeField = ActiveField.quantity;
      }
      _focusActiveField();
    });
  }

  void _handleDiscountTap() async {
    final newDiscount = await DiscountCalculatorDialog.show(context, _discountStr, _priceStr);
    if (newDiscount != null && mounted) {
      setState(() => _discountStr = newDiscount.isEmpty ? '0' : newDiscount);
    }
  }

  void _submit() {
    final priceStr = _priceStr.trim();
    final qtyStr = _qtyStr.trim();
    final packQtyStr = _packQtyStr.trim();

    final pricePerUnit = priceStr.isEmpty ? null : double.tryParse(priceStr);
    final qty = qtyStr.isEmpty ? null : double.tryParse(qtyStr);
    final packQty = (_hasPack && packQtyStr.isNotEmpty) ? double.tryParse(packQtyStr) : null;
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

    if (pricePerUnit != null && (discount < 0 || discount > 100)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid discount percentage')));
      return;
    }

    widget.onSubmit(pricePerUnit, qty, packQty, discount, _isWeight, _pendingImage, _imageRemoved);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: PurchasedItemFormHeader(
            title: widget.title,
            isWeight: _isWeight,
            hasPack: _hasPack,
            onWeightChanged: _handleWeightToggle,
            onLongPressToggle: _handlePackToggle,
          ),
        ),
        const SizedBox(height: 8),

        if (_historyFuture != null)
          FutureBuilder<List<PurchasedItemWithPurchase>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.length >= 2) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                  child: ItemPriceHistoryChart(history: snapshot.data!, isMinimal: true),
                );
              }
              return const SizedBox.shrink();
            },
          ),

        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: _buildFieldsRow(context.weightUnit, context.currencySymbol),
        ),

        const SizedBox(height: 16),

        ItemFormKeypad(
          isLoading: widget.isLoading,
          itemName: widget.itemName,
          imagePath: _imageRemoved ? null : _imagePath,
          pendingImage: _pendingImage,
          onImagePicked: (file) => setState(() {
            _pendingImage = file;
            _imageRemoved = false;
          }),
          onImageRemoved: () => setState(() {
            _pendingImage = null;
            _imageRemoved = true;
          }),
          discountStr: _discountStr,
          isTeleKeypad: context.isTelephoneLayout,
          onKeyPressed: _handleKeypadPress,
          onNameTap: widget.onNameTap,
          onDiscountTap: _handleDiscountTap,
          onSubmit: _submit,
          onIncrement: _incrementQuantity,
          onDecrement: _decrementQuantity,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _handleUnitPriceCalulatorTap(String currencySymbol, String weightUnit) async {
    HapticFeedback.lightImpact();

    final result = await UnitPriceCalculatorDialog.show(
      context: context,
      currentQuantity: _qtyStr,
      currentListingPrice: _priceStr,
      isWeight: _isWeight,
      currencySymbol: currencySymbol,
      discount: double.tryParse(_discountStr) ?? 0.0,
      weightUnit: weightUnit,
    );

    if (result != null && result.price.isNotEmpty && result.quantity.isNotEmpty && mounted) {
      HapticFeedback.selectionClick();

      setState(() {
        _priceStr = result.price;
        _priceController.text = result.price;

        _qtyStr = result.quantity;
        _qtyController.text = result.quantity;

        final double p = double.tryParse(_priceStr) ?? 0.0;
        final double q = double.tryParse(_qtyStr) ?? 0.0;
        final double packQ = _hasPack ? (double.tryParse(_packQtyStr) ?? 1.0) : 1.0;
        if (p > 0 && q > 0) {
          _totalStr = (p * q * packQ).toInputString();
          _totalController.text = _totalStr;
        }

        _activeField = ActiveField.quantity;
        _focusActiveField();
      });
    }
  }

  Widget _buildFieldsRow(String weightUnit, String currencySymbol) {
    final isCompact = context.isCompactPriceInput;

    if (_hasPack) {
      final packQtyBox = InputFieldBox(
        label: 'Packs',
        value: _packQtyStr,
        isActive: _activeField == ActiveField.packQuantity,
        onTap: () {
          setState(() => _activeField = ActiveField.packQuantity);
          _packQtyFocusNode.requestFocus();
        },
        controller: _packQtyController,
        focusNode: _packQtyFocusNode,
      );

      final qtyBox = InputFieldBox(
        label: _isWeight ? 'Weight ($weightUnit)' : 'Pcs / Pack',
        suffixText: _isWeight ? weightUnit : '',
        value: _qtyStr,
        isActive: _activeField == ActiveField.quantity,
        onTap: () {
          setState(() => _activeField = ActiveField.quantity);
          _qtyFocusNode.requestFocus();
        },
        controller: _qtyController,
        focusNode: _qtyFocusNode,
      );

      final priceBox = InputFieldBox(
        label: _isWeight ? '$currencySymbol Price (/$weightUnit)' : '$currencySymbol Unit Price',
        prefixText: '$currencySymbol ',
        value: _priceStr,
        isActive: _activeField == ActiveField.price,
        onTap: () {
          setState(() => _activeField = ActiveField.price);
          _priceFocusNode.requestFocus();
        },
        controller: _priceController,
        focusNode: _priceFocusNode,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calculate_outlined),
          onPressed: () => _handleUnitPriceCalulatorTap(currencySymbol, weightUnit),
          tooltip: 'Calculate unit price',
          color: Theme.of(context).colorScheme.primary,
        ),
      );

      if (isCompact) {
        return Row(
          spacing: 6,
          children: [
            Expanded(flex: 3, child: packQtyBox),
            Expanded(flex: 4, child: qtyBox),
            Expanded(flex: 5, child: priceBox),
          ],
        );
      } else {
        final totalBox = InputFieldBox(
          label: '$currencySymbol Total',
          prefixText: '$currencySymbol ',
          value: _totalStr,
          isActive: _activeField == ActiveField.total,
          onTap: () {
            setState(() => _activeField = ActiveField.total);
            _totalFocusNode.requestFocus();
          },
          controller: _totalController,
          focusNode: _totalFocusNode,
        );

        return Row(
          spacing: 6,
          children: [
            Expanded(flex: 3, child: packQtyBox),
            Expanded(flex: 3, child: qtyBox),
            Expanded(flex: 3, child: priceBox),
            Expanded(flex: 3, child: totalBox),
          ],
        );
      }
    }

    Widget buildQuantityField() {
      final colorScheme = Theme.of(context).colorScheme;
      final isQtyActive = _activeField == ActiveField.quantity;
      if (_isWeight) {
        return InputFieldBox(
          label: 'Weight ($weightUnit)',
          suffixText: weightUnit,
          value: _qtyStr,
          isActive: isQtyActive,
          onTap: () {
            setState(() => _activeField = ActiveField.quantity);
            _qtyFocusNode.requestFocus();
          },
          controller: _qtyController,
          focusNode: _qtyFocusNode,
        );
      } else {
        return InputFieldBox(
          label: 'Quantity',
          value: _qtyStr,
          textAlign: TextAlign.center,
          isActive: isQtyActive,
          onTap: () {
            setState(() => _activeField = ActiveField.quantity);
            _qtyFocusNode.requestFocus();
          },
          controller: _qtyController,
          focusNode: _qtyFocusNode,
          prefixIcon: IconButton(
            icon: const Icon(Icons.remove),
            onPressed: _decrementQuantity,
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
              shape: const CircleBorder(),
            ),
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.add),
            onPressed: _incrementQuantity,
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
              shape: const CircleBorder(),
            ),
          ),
        );
      }
    }

    if (isCompact) {
      return Row(
        spacing: 8,
        children: [
          Expanded(flex: 5, child: buildQuantityField()),
          Expanded(
            flex: 8,
            child: InputFieldBox(
              label: _isWeight
                  ? '$currencySymbol Unit Price (per $weightUnit)'
                  : '$currencySymbol Unit Price (per item)',
              prefixText: '$currencySymbol ',
              value: _priceStr,
              isActive: _activeField == ActiveField.price,
              onTap: () {
                setState(() => _activeField = ActiveField.price);
                _priceFocusNode.requestFocus();
              },
              controller: _priceController,
              focusNode: _priceFocusNode,
              suffixText: _isWeight ? '/$weightUnit' : '',
              suffixIcon: IconButton(
                icon: const Icon(Icons.calculate_outlined),
                onPressed: () => _handleUnitPriceCalulatorTap(currencySymbol, weightUnit),
                tooltip: 'Calculate unit price',
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        spacing: 8,
        children: [
          Expanded(flex: 4, child: buildQuantityField()),
          Expanded(
            flex: 4,
            child: InputFieldBox(
              label: _isWeight
                  ? '$currencySymbol Price (/$weightUnit)'
                  : '$currencySymbol Unit Price',
              prefixText: '$currencySymbol ',
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
          Expanded(
            flex: 4,
            child: InputFieldBox(
              label: '$currencySymbol Total',
              prefixText: '$currencySymbol ',
              value: _totalStr,
              isActive: _activeField == ActiveField.total,
              onTap: () {
                setState(() => _activeField = ActiveField.total);
                _totalFocusNode.requestFocus();
              },
              controller: _totalController,
              focusNode: _totalFocusNode,
            ),
          ),
        ],
      );
    }
  }
}
