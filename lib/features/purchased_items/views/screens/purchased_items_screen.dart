import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/features/purchased_items/views/widgets/add_purchased_item_dialog.dart';
import 'package:shopping_assist/core/widgets/empty_state.dart';
import 'package:shopping_assist/features/purchased_items/repositories/purchased_items_repository.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';

class PurchasedItemsScreen extends StatelessWidget {
  final Purchase purchase;
  final Group? group;

  const PurchasedItemsScreen({
    super.key,
    required this.purchase,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<PurchasedItemsRepository>();
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: Text(purchase.name),
        backgroundColor: colorScheme.primaryContainer,
      ),
      body: StreamBuilder<List<PurchasedItemWithDetails>>(
        stream: repo.watchPurchasedItems(purchase.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final purchasedItems = snapshot.data ?? [];

          if (purchasedItems.isEmpty) {
            return const EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your Cart is Ready',
              message: 'Add items to your purchase to see the running total.',
            );
          }

          return ListView.builder(
            itemCount: purchasedItems.length,
            itemBuilder: (context, index) {
              final details = purchasedItems[index];
              final pItem = details.purchasedItem;
              final item = details.item;
              final total = (pItem.price - pItem.discount) * pItem.quantity;

              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.label_outline),
                    title: Text(item.name),
                    subtitle: Text(
                      'Qty: ${pItem.quantity}${pItem.isWeight ? "kg" : ""} | '
                      'Price: $currency${pItem.price} | '
                      'Disc: $currency${pItem.discount}\n'
                      'Total: $currency${total.toStringAsFixed(2)}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                      ),
                      onPressed: () => repo.deletePurchasedItem(pItem.id),
                    ),
                  ),
                  if (index < purchasedItems.length - 1)
                    const Divider(height: 1),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (context) =>
              AddPurchasedItemDialog(purchase: purchase, group: group),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
