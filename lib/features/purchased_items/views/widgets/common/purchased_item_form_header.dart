import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';

class PurchasedItemFormHeader extends StatelessWidget {
  final String title;
  final bool isWeight;
  final bool hasPack;
  final ValueChanged<bool> onWeightChanged;
  final VoidCallback onLongPressToggle;

  const PurchasedItemFormHeader({
    super.key,
    required this.title,
    required this.isWeight,
    this.hasPack = false,
    required this.onWeightChanged,
    required this.onLongPressToggle,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.currencySymbol;
    final weightUnit = context.weightUnit;
    final colorScheme = Theme.of(context).colorScheme;

    String modeText;
    if (hasPack) {
      modeText = isWeight ? '$currencySymbol/$weightUnit + pcs' : '$currencySymbol/item + pack';
    } else {
      modeText = isWeight ? '$currencySymbol/$weightUnit' : '$currencySymbol/item';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        Row(
          children: [
            Text(
              modeText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: hasPack ? colorScheme.tertiary : colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                onWeightChanged(isWeight);
              },
              onLongPress: () {
                HapticFeedback.mediumImpact();
                onLongPressToggle();
              },
              child: AbsorbPointer(
                child: Switch(
                  value: isWeight || (hasPack && isWeight),
                  onChanged: (_) {},
                  thumbIcon: WidgetStateProperty.resolveWith((states) {
                    if (hasPack) {
                      return const Icon(Icons.layers_outlined, size: 16);
                    }
                    return null;
                  }),
                  inactiveThumbColor: hasPack ? colorScheme.tertiary : null,
                  activeThumbColor: hasPack ? colorScheme.tertiary : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
