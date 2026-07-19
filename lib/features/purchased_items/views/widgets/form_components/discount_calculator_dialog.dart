import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import 'package:shopping_assist/features/purchased_items/views/widgets/form_components/calculator_title.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';

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

  /// To prevent round-tripping issues (where both 200 and 200.1 are 13% of 230)
  /// More decimal precision is needed for more percentage resolution
  /// 4 is good for typical retail calculations
  int retailPrecision = 4;

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
    Decimal list = Decimal.tryParse(_listingPriceCtrl.text) ?? Decimal.zero;
    Decimal perc = Decimal.tryParse(_discountPercentCtrl.text) ?? Decimal.zero;
    if (perc == Decimal.zero) return;
    if (list > Decimal.zero) {
      final discRat = (list * perc) / Decimal.parse('100');
      Decimal disc = discRat.toDecimal(scaleOnInfinitePrecision: retailPrecision);
      _discountAmountCtrl.text = _format(disc);
      Decimal sell = list - disc;
      if (sell < Decimal.zero) sell = Decimal.zero;
      _sellingPriceCtrl.text = _format(sell);
    }
  }

  String _format(Decimal value, {int precision = 2}) {
    if (value == Decimal.zero) return '';
    String str = value.toDouble().toStringAsFixed(precision);
    if (str.endsWith('.00')) return str.substring(0, str.length - 3);
    if (str.endsWith('0')) return str.substring(0, str.length - 1);
    return str;
  }

  void _onListingPriceChanged(String val) {
    if (_isUpdating) return;
    _isUpdating = true;
    Decimal list = Decimal.tryParse(val) ?? Decimal.zero;

    if (_lastEdited == _EditType.percentage) {
      Decimal perc = Decimal.tryParse(_discountPercentCtrl.text) ?? Decimal.zero;
      final discRat = (list * perc) / Decimal.parse('100');
      Decimal disc = discRat.toDecimal(scaleOnInfinitePrecision: retailPrecision);
      Decimal sell = list - disc;
      _discountAmountCtrl.text = _format(disc);
      _sellingPriceCtrl.text = _format(sell);
    } else if (_lastEdited == _EditType.sellingPrice) {
      Decimal sell = Decimal.tryParse(_sellingPriceCtrl.text) ?? Decimal.zero;
      Decimal disc = list - sell;
      Decimal perc = Decimal.zero;
      if (list > Decimal.zero) {
        final percRat = (disc / list) * Decimal.parse('100').toRational();
        perc = percRat.toDecimal(scaleOnInfinitePrecision: retailPrecision);
      }
      _discountAmountCtrl.text = _format(disc);
      _discountPercentCtrl.text = _format(perc, precision: retailPrecision);
    } else {
      Decimal disc = Decimal.tryParse(_discountAmountCtrl.text) ?? Decimal.zero;
      Decimal perc = Decimal.zero;
      if (list > Decimal.zero) {
        final pRat = (disc / list) * Decimal.parse('100').toRational();
        perc = pRat.toDecimal(scaleOnInfinitePrecision: retailPrecision);
      }
      Decimal sell = list - disc;
      _discountPercentCtrl.text = _format(perc, precision: retailPrecision);
      _sellingPriceCtrl.text = _format(sell);
    }
    _isUpdating = false;
  }

  void _onDiscountAmountChanged(String val) {
    if (_isUpdating) return;
    _isUpdating = true;
    _lastEdited = _EditType.discount;
    Decimal disc = Decimal.tryParse(val) ?? Decimal.zero;
    Decimal list = Decimal.tryParse(_listingPriceCtrl.text) ?? Decimal.zero;

    Decimal perc = Decimal.zero;
    if (list > Decimal.zero) {
      final percRat = (disc / list) * Decimal.parse('100').toRational();
      perc = percRat.toDecimal(scaleOnInfinitePrecision: retailPrecision);
    }
    Decimal sell = list - disc;
    _discountPercentCtrl.text = _format(perc, precision: retailPrecision);
    _sellingPriceCtrl.text = _format(sell);
    _isUpdating = false;
  }

  void _onDiscountPercentChanged(String val) {
    if (_isUpdating) return;
    _isUpdating = true;
    _lastEdited = _EditType.percentage;
    Decimal perc = Decimal.tryParse(val) ?? Decimal.zero;
    Decimal list = Decimal.tryParse(_listingPriceCtrl.text) ?? Decimal.zero;

    final discRat = (list * perc) / Decimal.parse('100');
    Decimal disc = discRat.toDecimal(scaleOnInfinitePrecision: retailPrecision);
    Decimal sell = list - disc;
    _discountAmountCtrl.text = _format(disc);
    _sellingPriceCtrl.text = _format(sell);
    _isUpdating = false;
  }

  void _onSellingPriceChanged(String val) {
    if (_isUpdating) return;
    _isUpdating = true;
    _lastEdited = _EditType.sellingPrice;
    Decimal sell = Decimal.tryParse(val) ?? Decimal.zero;
    Decimal list = Decimal.tryParse(_listingPriceCtrl.text) ?? Decimal.zero;

    Decimal disc = list - sell;
    Decimal perc = Decimal.zero;
    if (list > Decimal.zero) {
      final percRat = (disc / list) * Decimal.parse('100').toRational();
      perc = percRat.toDecimal(scaleOnInfinitePrecision: retailPrecision);
    }
    _discountAmountCtrl.text = _format(disc);
    _discountPercentCtrl.text = _format(perc, precision: retailPrecision);
    _isUpdating = false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: CalculatorTitle(mainText: 'Discount', icon: Icons.discount_outlined),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              readOnly: true,
              controller: _listingPriceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Listing Price',
                prefixText: context.currencySymbol,
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
                    decoration: InputDecoration(
                      labelText: 'Discount',
                      border: OutlineInputBorder(),
                      prefixText: '-${context.currencySymbol}',
                    ),
                    onChanged: _onDiscountAmountChanged,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _discountPercentCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Percentage',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.secondaryContainer,
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
