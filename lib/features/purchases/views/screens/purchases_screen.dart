import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/widgets/empty_state.dart';
import 'package:shopping_assist/features/purchased_items/views/screens/purchased_items_screen.dart';
import 'package:shopping_assist/features/purchases/repositories/purchases_repository.dart';
import 'package:shopping_assist/features/purchases/views/widgets/add_purchase_dialog.dart';

class PurchasesScreen extends StatelessWidget {
  final Group group;

  const PurchasesScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final repo = context.watch<PurchasesRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${group.name} Purchases'),
        backgroundColor: colorScheme.primaryContainer,
      ),
      body: StreamBuilder<List<Purchase>>(
        stream: repo.watchPurchasesInGroup(group.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final purchases = snapshot.data ?? [];

          if (purchases.isEmpty) {
            return const EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'No Purchases Yet',
              message: 'Start a new shopping event by adding a purchase.',
            );
          }

          return ListView.builder(
            itemCount: purchases.length,
            itemBuilder: (context, index) {
              final purchase = purchases[index];
              return ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: Text(purchase.name),
                subtitle: Text(
                  '${purchase.purchaseDate.day}/${purchase.purchaseDate.month}/${purchase.purchaseDate.year}',
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  onPressed: () =>
                      _confirmDelete(context, repo, purchase, colorScheme),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PurchasedItemsScreen(purchase: purchase, group: group),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AddPurchaseDialog(groupId: group.id),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    PurchasesRepository repo,
    Purchase purchase,
    ColorScheme colorScheme,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Purchase Event?'),
        content: Text('Are you sure you want to delete "${purchase.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            onPressed: () {
              repo.deletePurchase(purchase.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
