import 'package:flutter/material.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';

class PurchasedItemFormHeader extends StatelessWidget {
  final String title;
  final bool isWeight;
  final ValueChanged<bool> onWeightChanged;

  const PurchasedItemFormHeader({
    super.key,
    required this.title,
    required this.isWeight,
    required this.onWeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.currencySymbol;
    final weightUnit = context.weightUnit;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        Row(
          children: [
            Text(
              '$currencySymbol/$weightUnit',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Switch(value: isWeight, onChanged: onWeightChanged),
          ],
        ),
      ],
    );
  }
}
