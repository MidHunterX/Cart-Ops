import 'package:flutter/material.dart';

enum _EditType { discount, percentage, sellingPrice }

class DiscountCalculatorDialog extends StatefulWidget {
  final String initialDiscount;
  final String initialPrice;

  const DiscountCalculatorDialog({
    super.key,
    required this.initialDiscount,
    required this.initialPrice,
  });

  static Future<String?> show(
    BuildContext context,
    String currentDiscount,
    String currentPrice,
  ) async {
    return showDialog<String>(
      context: context,
      builder: (context) =>
          DiscountCalculatorDialog(initialDiscount: currentDiscount, initialPrice: currentPrice),
    );
  }

  @override
  State<DiscountCalculatorDialog> createState() => _DiscountCalculatorDialogState();
}

class _DiscountCalculatorDialogState extends State<DiscountCalculatorDialog> {
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
      double p = double.tryParse(_discountPercentCtrl.text) ?? 0.0;
      double d = l * (p / 100);
      double s = l - d;
      _discountAmountCtrl.text = _format(d);
      _sellingPriceCtrl.text = _format(s);
    } else if (_lastEdited == _EditType.sellingPrice) {
      double s = double.tryParse(_sellingPriceCtrl.text) ?? 0.0;
      double d = l - s;
      double p = l > 0 ? (d / l) * 100 : 0.0;
      _discountAmountCtrl.text = _format(d);
      _discountPercentCtrl.text = _format(p);
    } else {
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
      title: Text('Discount Calculator', style: Theme.of(context).textTheme.titleLarge),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
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
