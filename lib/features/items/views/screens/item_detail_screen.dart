import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/utils/number_formatter.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';

class ItemDetailScreen extends StatelessWidget {
  final Item item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ItemsRepository>();
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Item Details'), backgroundColor: colorScheme.primaryContainer),
      body: FutureBuilder<List<PurchasedItemWithPurchase>>(
        future: repo.getPurchaseHistoryForItem(item.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final history = snapshot.data ?? [];
          final count = history.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: item.imagePath != null && File(item.imagePath!).existsSync()
                        ? Image.file(
                            File(item.imagePath!),
                            height: 200,
                            width: double.maxFinite,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            height: 200,
                            width: double.maxFinite,
                            color: colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.image_not_supported, size: 80),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(item.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),
                Text(
                  'Price History ($count)',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
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
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.secondaryContainer,
                          child: Icon(Icons.history, color: colorScheme.onSecondaryContainer),
                        ),
                        title: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Quantity: ${p.quantity.toWeightString(p.isWeight ? 'kg' : '')}'),
                          ],
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              p.price.toCurrencyString(currency),
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
