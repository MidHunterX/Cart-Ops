import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/utils/number_formatter.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';

class ItemDetailScreen extends StatelessWidget {
  final Item item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ItemsRepository>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(item.name), backgroundColor: colorScheme.primaryContainer),
      body: FutureBuilder(
        future: Future.wait([
          repo.countPurchasesForItem(item.id),
          repo.getPurchasedItemsForItem(item.id),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final count = snapshot.data?[0] as int? ?? 0;
          final purchasedItems = snapshot.data?[1] as List<PurchasedItem>? ?? [];

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
                Text('Name', style: Theme.of(context).textTheme.labelMedium),
                Text(item.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text('Times Bought', style: Theme.of(context).textTheme.labelMedium),
                Text('$count', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),
                Text(
                  'Price History',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (purchasedItems.isEmpty)
                  const Text('No purchases recorded yet.')
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: purchasedItems.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (ctx, index) {
                      final p = purchasedItems[index];
                      return ListTile(
                        leading: Text('${index + 1}'),
                        title: Text('Price: ${p.price.toCurrencyString('\$')}'),
                        subtitle: Text('Qty: ${p.quantity.toWeightString(p.isWeight ? 'kg' : '')}'),
                        trailing: Text('Discount: ${p.discount.toCurrencyString('\$')}'),
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
