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
  _EditType _lastEdited = _EditType.discount;

  @override
  void initState() {
    super.initState();
    _listingPriceCtrl = TextEditingController(text: widget.initialPrice);
    _discountAmountCtrl = TextEditingController(
      text: widget.initialDiscount == '0' ? '' : widget.initialDiscount,
    );
    _discountPercentCtrl = TextEditingController();
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
    double disc = double.tryParse(_discountAmountCtrl.text) ?? 0.0;
    if (disc == 0) return;
    if (list > 0) {
      double perc = (disc / list) * 100;
      _discountPercentCtrl.text = _format(perc);
    }
    double sell = list - disc;
    if (sell < 0) sell = 0;
    _sellingPriceCtrl.text = _format(sell);
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
              decoration: const InputDecoration(
                labelText: 'Listing Price',
              ),
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
          onPressed: () => Navigator.pop(context, _discountAmountCtrl.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
