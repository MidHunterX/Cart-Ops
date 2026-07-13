import 'package:flutter/material.dart';
import 'package:shopping_assist/core/utils/number_formatter.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class PurchaseSummaryCard extends StatelessWidget {
  final int itemCount;
  final double total;
  final double? budget;

  final double headerIconSize = 28;

  const PurchaseSummaryCard({super.key, required this.itemCount, required this.total, this.budget});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currency = context.watch<SettingsProvider>().currencySymbol;

    final hasBudget = budget != null && budget! > 0;

    return Material(
      color: colorScheme.primaryContainer,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildItemsCount(context, colorScheme),
                Container(width: 1, height: 40, color: colorScheme.onPrimaryContainer),
                _buildTotal(context, colorScheme, currency),
              ],
            ),
            if (hasBudget) ...[
              const SizedBox(height: 16),
              _buildBudget(context, colorScheme, currency),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCount(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(
          Icons.shopping_cart_outlined,
          color: colorScheme.onPrimaryContainer,
          size: headerIconSize,
        ),
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
    );
  }

  Widget _buildTotal(BuildContext context, ColorScheme colorScheme, String currency) {
    return Row(
      children: [
        Icon(
          Icons.receipt_long_outlined,
          color: colorScheme.onPrimaryContainer,
          size: headerIconSize,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              total.toCurrencyString(currency),
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
    );
  }

  Widget _buildBudget(BuildContext context, ColorScheme colorScheme, String currency) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget: ${budget!.toCurrencyString(currency)}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimaryContainer),
              ),
              Text(
                'Remaining: ${(budget! - total).toCurrencyString(currency)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (total / budget!).clamp(0.0, 1.0),
            backgroundColor: colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
            color: total > budget! ? colorScheme.error : colorScheme.primary,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
