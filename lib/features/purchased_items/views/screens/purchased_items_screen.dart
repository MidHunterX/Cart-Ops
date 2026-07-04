import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/features/purchased_items/views/widgets/add_purchased_item_sheet.dart';
import 'package:shopping_assist/core/widgets/empty_state.dart';
import 'package:shopping_assist/features/purchased_items/repositories/purchased_items_repository.dart';
import 'package:shopping_assist/features/purchased_items/views/widgets/purchased_item_tile.dart';
import 'package:shopping_assist/features/purchased_items/views/widgets/purchase_summary_card.dart';

class PurchasedItemsScreen extends StatelessWidget {
  final Purchase purchase;
  final Group? group;

  const PurchasedItemsScreen({super.key, required this.purchase, required this.group});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<PurchasedItemsRepository>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(purchase.name), backgroundColor: colorScheme.primaryContainer),
      body: StreamBuilder<List<PurchasedItemWithDetails>>(
        stream: repo.watchPurchasedItems(purchase.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final purchasedItems = snapshot.data ?? [];
          final totalItems = purchasedItems.length;
          final totalPrice = purchasedItems.fold<double>(
            0.0,
            (sum, details) =>
                sum +
                (((details.purchasedItem.price ?? 0.0) - details.purchasedItem.discount) *
                    (details.purchasedItem.quantity ?? 0.0)),
          );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PurchaseSummaryCard(itemCount: totalItems, total: totalPrice),
              ),
              if (purchasedItems.isEmpty)
                SliverFillRemaining(
                  child: const EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Your Cart is Ready',
                    message: 'Add items to your purchase to see the running total.',
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final details = purchasedItems[index];
                    return PurchasedItemTile(
                      details: details,
                      index: index,
                      totalItems: totalItems,
                    );
                  }, childCount: purchasedItems.length),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => AddPurchasedItemSheet(purchase: purchase, group: group),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }
}
