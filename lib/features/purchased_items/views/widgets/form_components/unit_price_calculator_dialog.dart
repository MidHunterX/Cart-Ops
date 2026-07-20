import 'package:flutter/material.dart';
import 'package:shopping_assist/core/utils/number_formatter.dart';
import 'package:shopping_assist/features/purchased_items/views/widgets/form_components/calculator_title.dart';

class UnitPriceCalculatorDialog extends StatefulWidget {
  final String initialQuantity;
  final String initialListingPrice;
  final bool isWeight;
  final double discount;
  final String? currencySymbol;
  final String? weightUnit;

  const UnitPriceCalculatorDialog({
    super.key,
    required this.initialQuantity,
    required this.initialListingPrice,
    required this.isWeight,
    required this.discount,
    this.currencySymbol,
    this.weightUnit,
  });

  static Future<String?> show({
    required BuildContext context,
    required String currentQuantity,
    required String currentListingPrice,
    required bool isWeight,
    required double discount,
    String? currencySymbol,
    String? weightUnit,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => UnitPriceCalculatorDialog(
        initialQuantity: currentQuantity,
        initialListingPrice: currentListingPrice,
        isWeight: isWeight,
        discount: discount,
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
    final listingPrice = double.tryParse(widget.initialListingPrice) ?? 0.0;
    final quantity = double.tryParse(widget.initialQuantity) ?? 0.0;

    String totalPrice;
    if (listingPrice > 0 && quantity > 0) {
      totalPrice = (listingPrice * quantity).toPriceString();
    } else {
      totalPrice = widget.initialListingPrice;
    }

    _totalAmountCtrl = TextEditingController(text: totalPrice);
    _quantityCtrl = TextEditingController(text: widget.initialQuantity);
    _resultCtrl = TextEditingController();

    _calculate();
  }

  void _calculate() {
    final total = double.tryParse(_totalAmountCtrl.text) ?? 0.0;
    final qty = double.tryParse(_quantityCtrl.text) ?? 0.0;

    if (total > 0 && qty > 0) {
      final unitPrice = total / qty;
      _resultCtrl.text = unitPrice.toPriceString();
    } else {
      _resultCtrl.text = '';
    }
    setState(() {}); // Rebuild to update the real-time discounted header
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
          const SizedBox(height: 16),
          TextField(
            controller: _quantityCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              suffixText: widget.isWeight ? widget.weightUnit : '',
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
              border: const OutlineInputBorder(),
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
              labelText: 'Unit Price',
              filled: true,
              fillColor: Theme.of(context).colorScheme.secondaryContainer,
              border: const OutlineInputBorder(),
              // helperText: '* Calculated from above values',
            ),
          ),
          if (widget.discount > 0) const SizedBox(height: 16),
          if (widget.discount > 0) _buildDiscountHeader(),
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

  Widget _buildDiscountHeader() {
    final double total = double.tryParse(_totalAmountCtrl.text) ?? 0.0;
    final double discountedTotal = total * (1 - widget.discount / 100);
    final double unitPrice = double.tryParse(_resultCtrl.text) ?? 0.0;
    final double discountedUnitPrice = unitPrice * (1 - widget.discount / 100);
    final colorscheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.discount.toStringAsFixed(0)}% Discount Applied',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorscheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(height: 12),
        _buildDiscountRow(
          label: 'Unit Price:',
          original: unitPrice,
          discounted: discountedUnitPrice,
          symbol: widget.currencySymbol ?? '',
        ),
        const Divider(height: 12),
        _buildDiscountRow(
          label: 'Total Price:',
          original: total,
          discounted: discountedTotal,
          symbol: widget.currencySymbol ?? '',
        ),
      ],
    );
  }

  Widget _buildDiscountRow({
    required String label,
    required double original,
    required double discounted,
    required String symbol,
  }) {
    final colorscheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Row(
          children: [
            Text(
              '$symbol${original.toPriceString()}',
              style: TextStyle(
                decoration: TextDecoration.lineThrough,
                fontSize: 12,
                color: colorscheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$symbol${discounted.toPriceString()}',
              style: TextStyle(fontWeight: FontWeight.bold, color: colorscheme.primary),
            ),
          ],
        ),
      ],
    );
  }
}
