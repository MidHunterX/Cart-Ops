import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/database/database.dart';
import 'package:shopping_assist/database/daos/purchased_items_dao.dart';
import 'package:shopping_assist/presentation/widgets/add_purchased_item_dialog.dart';

class PurchasedItemsScreen extends StatelessWidget {
  final Purchase purchase;
  final Group group;

  const PurchasedItemsScreen({
    super.key,
    required this.purchase,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(purchase.name),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: StreamBuilder<List<PurchasedItemWithDetails>>(
        stream: db.purchasedItemsDao.watchPurchasedItems(purchase.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final purchasedItems = snapshot.data ?? [];

          if (purchasedItems.isEmpty) {
            return const Center(child: Text('No items in this purchase yet.'));
          }

          return ListView.builder(
            itemCount: purchasedItems.length,
            itemBuilder: (context, index) {
              final details = purchasedItems[index];
              final pItem = details.purchasedItem;
              final item = details.item;

              final total = (pItem.price - pItem.discount) * pItem.quantity;

              return ListTile(
                leading: const Icon(Icons.label_outline),
                title: Text(item.name),
                subtitle: Text(
                  'Qty: ${pItem.quantity}${pItem.isWeight ? "kg" : ""} | '
                  'Price: \$${pItem.price} | '
                  'Disc: \$${pItem.discount}\n'
                  'Total: \$${total.toStringAsFixed(2)}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      db.purchasedItemsDao.deletePurchasedItem(pItem.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) =>
                AddPurchasedItemDialog(purchase: purchase, group: group),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
