import 'package:flutter/material.dart';
import 'package:shopping_assist/core/database/database.dart';

class ItemDialogs {
  static Future<void> showNameDialog({
    required BuildContext context,
    required String currentName,
    required List<Item> allItems,
    required void Function(String name, int? itemId) onSave,
  }) async {
    final nameCtrl = TextEditingController(text: currentName);
    int? selectedItemId;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Item Name', style: Theme.of(context).textTheme.titleLarge),
        content: Autocomplete<Item>(
          initialValue: TextEditingValue(text: currentName),
          displayStringForOption: (Item option) => option.name,
          optionsViewOpenDirection: OptionsViewOpenDirection.up,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<Item>.empty();
            }
            final query = textEditingValue.text.toLowerCase();
            return allItems.where((Item option) => option.name.toLowerCase().contains(query));
          },
          onSelected: (Item selection) {
            nameCtrl.text = selection.name;
            selectedItemId = selection.id;
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            controller.addListener(() => nameCtrl.text = controller.text);
            return TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search or enter new item',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                onSave(nameCtrl.text, selectedItemId);
                Navigator.pop(context);
              },
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              onSave(nameCtrl.text, selectedItemId);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  static Future<String?> showDiscountDialog(
    BuildContext context,
    String currentDiscount,
    String currentPrice,
  ) async {
    return showDialog<String>(
      context: context,
      builder: (context) =>
          _DiscountCalculatorDialog(initialDiscount: currentDiscount, initialPrice: currentPrice),
    );
  }

  static Future<String?> showUnitPriceCalculatorDialog({
    required BuildContext context,
    required String currentQuantity,
    required String currentFinalPrice,
    required bool isWeight,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => _UnitPriceCalculatorDialog(
        initialQuantity: currentQuantity,
        initialFinalPrice: currentFinalPrice,
        isWeight: isWeight,
      ),
    );
  }
}

enum _EditType { discount, percentage, sellingPrice }

class _DiscountCalculatorDialog extends StatefulWidget {
  final String initialDiscount;
  final String initialPrice;

  const _DiscountCalculatorDialog({required this.initialDiscount, required this.initialPrice});

  @override
  State<_DiscountCalculatorDialog> createState() => _DiscountCalculatorDialogState();
}

class _DiscountCalculatorDialogState extends State<_DiscountCalculatorDialog> {
  late TextEditingController _listingPriceCtrl;
  late TextEditingController _discountAmountCtrl;
  late TextEditingController _discountPercentCtrl;
  late TextEditingController _sellingPriceCtrl;

  bool _isUpdating = false;
  _EditType _lastEdited = _EditType.percentage; // Default mapping behavior

  @override
  void initState() {
    super.initState();
    _listingPriceCtrl = TextEditingController(text: widget.initialPrice);
    _discountPercentCtrl = TextEditingController(
      text: widget.initialDiscount == '0' ? '' : widget.initialDiscount,
    );
    _discountAmountCtrl = TextEditingController();
    _sellingPriceCtrl = TextEditingController();

    _calculateInitial();
  }

  @override
  void dispose() {
    _listingPriceCtrl.dispose();
    _discountAmountCtrl.dispose();
    _discountPercentCtrl.dispose();
    _sellingPriceCtrl.dispose();
    super.dispose();
  }

  void _calculateInitial() {
    double list = double.tryParse(_listingPriceCtrl.text) ?? 0.0;
    double perc = double.tryParse(_discountPercentCtrl.text) ?? 0.0;
    if (perc == 0) return;
    if (list > 0) {
      double disc = list * (perc / 100);
      _discountAmountCtrl.text = _format(disc);
      double sell = list - disc;
      if (sell < 0) sell = 0;
      _sellingPriceCtrl.text = _format(sell);
    }
  }

  String _format(double value) {
    if (value == 0 || value.isNaN || value.isInfinite) return '';
    String s = value.toStringAsFixed(2);
    if (s.endsWith('.00')) {
      return s.substring(0, s.length - 3);
    }
    if (s.endsWith('0')) {
      return s.substring(0, s.length - 1);
    }
    return s;
  }

  void _onListingPriceChanged(String val) {
    if (_isUpdating) return;
    _isUpdating = true;
    double l = double.tryParse(val) ?? 0.0;

    if (_lastEdited == _EditType.percentage) {
      // BEHAVIOR: recompute discount and selling price from new percentage
      double p = double.tryParse(_discountPercentCtrl.text) ?? 0.0;
      double d = l * (p / 100);
      double s = l - d;
      _discountAmountCtrl.text = _format(d);
      _sellingPriceCtrl.text = _format(s);
    } else if (_lastEdited == _EditType.sellingPrice) {
      // BEHAVIOR: recompute discount and percentage from new listing
      double s = double.tryParse(_sellingPriceCtrl.text) ?? 0.0;
      double d = l - s;
      double p = l > 0 ? (d / l) * 100 : 0.0;
      _discountAmountCtrl.text = _format(d);
      _discountPercentCtrl.text = _format(p);
    } else {
      // BEHAVIOR: recompute percentage and selling price from new listing
      double d = double.tryParse(_discountAmountCtrl.text) ?? 0.0;
      double p = l > 0 ? (d / l) * 100 : 0.0;
      double s = l - d;
      _discountPercentCtrl.text = _format(p);
      _sellingPriceCtrl.text = _format(s);
    }
    _isUpdating = false;
  }

  void _onDiscountAmountChanged(String val) {
    if (_isUpdating) return;
    _isUpdating = true;
    _lastEdited = _EditType.discount;
    double d = double.tryParse(val) ?? 0.0;
    double l = double.tryParse(_listingPriceCtrl.text) ?? 0.0;

    double p = l > 0 ? (d / l) * 100 : 0.0;
    double s = l - d;
    _discountPercentCtrl.text = _format(p);
    _sellingPriceCtrl.text = _format(s);
    _isUpdating = false;
  }

  void _onDiscountPercentChanged(String val) {
    if (_isUpdating) return;
    _isUpdating = true;
    _lastEdited = _EditType.percentage;
    double p = double.tryParse(val) ?? 0.0;
    double l = double.tryParse(_listingPriceCtrl.text) ?? 0.0;

    double d = l * (p / 100);
    double s = l - d;
    _discountAmountCtrl.text = _format(d);
    _sellingPriceCtrl.text = _format(s);
    _isUpdating = false;
  }

  void _onSellingPriceChanged(String val) {
    if (_isUpdating) return;
    _isUpdating = true;
    _lastEdited = _EditType.sellingPrice;
    double s = double.tryParse(val) ?? 0.0;
    double l = double.tryParse(_listingPriceCtrl.text) ?? 0.0;

    double d = l - s;
    double p = l > 0 ? (d / l) * 100 : 0.0;
    _discountAmountCtrl.text = _format(d);
    _discountPercentCtrl.text = _format(p);
    _isUpdating = false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Calculate Discount', style: Theme.of(context).textTheme.titleLarge),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              // NOTE: listing price is edited on forms instead. Single source of truth.
              readOnly: true,
              controller: _listingPriceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Listing Price'),
              onChanged: _onListingPriceChanged,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _discountAmountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Discount',
                      border: OutlineInputBorder(),
                      prefixText: '- ',
                    ),
                    onChanged: _onDiscountAmountChanged,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _discountPercentCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Percentage',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    onChanged: _onDiscountPercentChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sellingPriceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Selling Price',
                border: OutlineInputBorder(),
              ),
              onChanged: _onSellingPriceChanged,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _discountPercentCtrl.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _UnitPriceCalculatorDialog extends StatefulWidget {
  final String initialQuantity;
  final String initialFinalPrice;
  final bool isWeight;

  const _UnitPriceCalculatorDialog({
    required this.initialQuantity,
    required this.initialFinalPrice,
    required this.isWeight,
  });

  @override
  State<_UnitPriceCalculatorDialog> createState() => _UnitPriceCalculatorDialogState();
}

class _UnitPriceCalculatorDialogState extends State<_UnitPriceCalculatorDialog> {
  late TextEditingController _totalAmountCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _resultCtrl;

  @override
  void initState() {
    super.initState();
    _totalAmountCtrl = TextEditingController(
      text: widget.initialFinalPrice.isEmpty || widget.initialFinalPrice == '0'
          ? '0'
          : widget.initialFinalPrice,
    );
    _quantityCtrl = TextEditingController(
      text: widget.initialQuantity.isEmpty || widget.initialQuantity == '0'
          ? '1'
          : widget.initialQuantity,
    );
    _resultCtrl = TextEditingController();

    _calculate();
  }

  void _calculate() {
    final total = double.tryParse(_totalAmountCtrl.text) ?? 0.0;
    final qty = double.tryParse(_quantityCtrl.text) ?? 0.0;

    if (total > 0 && qty > 0) {
      final unitPrice = total / qty;
      String s = unitPrice.toStringAsFixed(2);
      // Clean up trailing zeros
      if (s.endsWith('.00')) s = s.substring(0, s.length - 3);
      _resultCtrl.text = s;
    } else {
      _resultCtrl.text = '';
    }
  }

  @override
  void dispose() {
    _totalAmountCtrl.dispose();
    _quantityCtrl.dispose();
    _resultCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Unit Price Calculator', style: Theme.of(context).textTheme.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _totalAmountCtrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Total Amount',
              border: OutlineInputBorder(),
              prefixText: '',
            ),
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quantityCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: widget.isWeight ? 'Total Weight' : 'Total Quantity/Pack Size',
              border: const OutlineInputBorder(),
              helperText: 'e.g., 6 for a 6-pack, or 1.5 for 1.5kg',
            ),
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _resultCtrl,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Price Per Unit',
              filled: true,
              fillColor: Theme.of(context).colorScheme.secondaryContainer,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _resultCtrl.text),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
