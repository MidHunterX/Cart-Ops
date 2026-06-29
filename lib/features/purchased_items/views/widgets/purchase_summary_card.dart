import 'package:flutter/material.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class PurchaseSummaryCard extends StatelessWidget {
  final int itemCount;
  final double total;

  const PurchaseSummaryCard({super.key, required this.itemCount, required this.total});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currency = context.watch<SettingsProvider>().currencySymbol;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Items Count
          Row(
            children: [
              Icon(Icons.shopping_bag_outlined, color: colorScheme.onPrimaryContainer, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemCount.toString().padLeft(2, '0'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Items',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ],
          ),
          Container(width: 1, height: 40, color: colorScheme.onPrimaryContainer),
          // Total
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$currency ${total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Total',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
