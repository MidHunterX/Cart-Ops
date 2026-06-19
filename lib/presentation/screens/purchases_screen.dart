import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/database/database.dart';
import 'package:shopping_assist/presentation/widgets/add_purchase_dialog.dart';
import 'package:shopping_assist/presentation/screens/purchased_items_screen.dart';

class PurchasesScreen extends StatelessWidget {
  final Group group;

  const PurchasesScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${group.name} Purchases'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: StreamBuilder<List<Purchase>>(
        stream: db.purchasesDao.watchPurchasesInGroup(group.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final purchases = snapshot.data ?? [];

          if (purchases.isEmpty) {
            return const Center(child: Text('No purchases yet. Add one!'));
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
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => db.purchasesDao.deletePurchase(purchase.id),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PurchasedItemsScreen(
                        purchase: purchase,
                        group: group,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddPurchaseDialog(groupId: group.id),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
