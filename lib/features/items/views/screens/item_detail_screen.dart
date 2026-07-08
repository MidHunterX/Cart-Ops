import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/utils/number_formatter.dart';
import 'package:shopping_assist/core/widgets/item_image_view.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';
import 'package:shopping_assist/features/items/views/widgets/item_price_history_chart.dart';

class ItemDetailScreen extends StatelessWidget {
  final Item item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ItemsRepository>();
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;
    final weightUnit = settings.weightUnit;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        backgroundColor: colorScheme.primaryContainer,
      ),
      body: FutureBuilder<List<PurchasedItemWithPurchase>>(
        future: repo.getPurchaseHistoryForItem(item.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final history = snapshot.data ?? [];
          final count = history.length;

          // TODO: Change dynamically based on viewport and datapoint string length
          final int maxDataPoints = 14;
          final displayHistory = history.take(maxDataPoints).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.imagePath != null)
                  Column(
                    children: [
                      Center(
                        child: ItemImageView(
                          imagePath: item.imagePath,
                          height: 200,
                          width: double.maxFinite,
                          borderRadius: BorderRadius.circular(12),
                          placeholderIcon: Icons.image_not_supported,
                          placeholderIconSize: 80,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                Text(item.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),

                if (history.length >= 2) ...[
                  Text('Price Trend', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  ItemPriceHistoryChart(history: displayHistory),
                  const SizedBox(height: 24),
                ],

                Text('Price History ($count)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (history.isEmpty)
                  const Text('No purchases recorded yet.')
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (ctx, index) {
                      final itemWithPurchase = history[index];
                      final p = itemWithPurchase.purchasedItem;
                      final purchase = itemWithPurchase.purchase;
                      final dateStr =
                          "${purchase.purchaseDate.year}"
                          "-${purchase.purchaseDate.month.toString().padLeft(2, '0')}"
                          "-${purchase.purchaseDate.day.toString().padLeft(2, '0')}";

                      return ListTile(
                        contentPadding: const EdgeInsets.all(0), // Remove default padding
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.secondaryContainer,
                          child: Icon(Icons.history, color: colorScheme.onSecondaryContainer),
                        ),
                        title: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Quantity: ${p.quantity?.toWeightString(p.isWeight ? weightUnit : '')}',
                            ),
                          ],
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              p.price!.toCurrencyString(currency),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (p.discount > 0)
                              Text(
                                'Discount: ${p.discount.toCurrencyString(currency)}',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
