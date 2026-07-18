import 'package:flutter/material.dart';

class UnitPriceCalculatorDialog extends StatefulWidget {
  final String initialQuantity;
  final String initialFinalPrice;
  final bool isWeight;

  const UnitPriceCalculatorDialog({
    super.key,
    required this.initialQuantity,
    required this.initialFinalPrice,
    required this.isWeight,
  });

  static Future<String?> show({
    required BuildContext context,
    required String currentQuantity,
    required String currentFinalPrice,
    required bool isWeight,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => UnitPriceCalculatorDialog(
        initialQuantity: currentQuantity,
        initialFinalPrice: currentFinalPrice,
        isWeight: isWeight,
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
