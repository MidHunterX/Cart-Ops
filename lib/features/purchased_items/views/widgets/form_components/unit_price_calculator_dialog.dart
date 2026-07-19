import 'package:flutter/material.dart';
import 'package:shopping_assist/features/purchased_items/views/widgets/form_components/calculator_title.dart';

class UnitPriceCalculatorDialog extends StatefulWidget {
  final String initialQuantity;
  final String initialFinalPrice;
  final bool isWeight;
  final String? currencySymbol;
  final String? weightUnit;

  const UnitPriceCalculatorDialog({
    super.key,
    required this.initialQuantity,
    required this.initialFinalPrice,
    required this.isWeight,
    this.currencySymbol,
    this.weightUnit,
  });

  static Future<String?> show({
    required BuildContext context,
    required String currentQuantity,
    required String currentFinalPrice,
    required bool isWeight,
    String? currencySymbol,
    String? weightUnit,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => UnitPriceCalculatorDialog(
        initialQuantity: currentQuantity,
        initialFinalPrice: currentFinalPrice,
        isWeight: isWeight,
        currencySymbol: currencySymbol ?? '',
        weightUnit: weightUnit ?? 'weight',
      ),
    );
  }

  @override
  State<UnitPriceCalculatorDialog> createState() => _UnitPriceCalculatorDialogState();
}

class _UnitPriceCalculatorDialogState extends State<UnitPriceCalculatorDialog> {
  late TextEditingController _totalAmountCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _resultCtrl;

  @override
  void initState() {
    super.initState();
    _totalAmountCtrl = TextEditingController(text: widget.initialFinalPrice);
    _quantityCtrl = TextEditingController(text: widget.initialQuantity);
    _resultCtrl = TextEditingController();

    _calculate();
  }

  void _calculate() {
    final total = double.tryParse(_totalAmountCtrl.text) ?? 0.0;
    final qty = double.tryParse(_quantityCtrl.text) ?? 0.0;

    if (total > 0 && qty > 0) {
      final unitPrice = total / qty;
      String s = unitPrice.toStringAsFixed(2);
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
      title: CalculatorTitle(mainText: 'Unit Price', icon: Icons.calculate_outlined),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _quantityCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              suffixText: widget.isWeight ? '${widget.weightUnit}' : '',
              labelText: widget.isWeight ? 'Total Weight (${widget.weightUnit})' : 'Total Quantity',
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _totalAmountCtrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixText: widget.currencySymbol,
              labelText: 'Total Price',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _resultCtrl,
            readOnly: true, // finding total price should be calculated by main form
            decoration: InputDecoration(
              prefixText: widget.currencySymbol,
              suffixText: widget.isWeight ? '/${widget.weightUnit}' : '',
              labelText: widget.isWeight ? 'Price per ${widget.weightUnit}' : 'Price per Unit',
              filled: true,
              fillColor: Theme.of(context).colorScheme.secondaryContainer,
              border: const OutlineInputBorder(),
              helperText: '* Calculated from above values',
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
