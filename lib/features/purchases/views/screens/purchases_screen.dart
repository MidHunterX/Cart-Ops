import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/widgets/dextrous_fab.dart';
import 'package:shopping_assist/features/purchased_items/views/screens/purchased_items_screen.dart';
import 'package:shopping_assist/features/purchases/repositories/purchases_repository.dart';
import 'package:shopping_assist/features/purchases/views/widgets/purchases_list.dart';
import 'package:shopping_assist/features/items/views/screens/items_screen.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import 'package:shopping_assist/features/settings/data/settings_data.dart';

class PurchasesScreen extends StatelessWidget {
  final Group group;

  const PurchasesScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<PurchasesRepository>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Purchases'),
            Text(group.name, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ItemsScreen(group: group)),
            ),
          ),
        ],
      ),
      floatingActionButton: DextrousFloatingActionButton(
        isCenter: settings.dominantHand == DominantHand.center,
        icon: Icons.shopping_cart,
        label: 'Add Purchase',
        onPressed: () async {
          final purchase = await repo.createPurchase(group.id);
          if (context.mounted) {
            await Future.delayed(const Duration(milliseconds: 300));
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PurchasedItemsScreen(purchase: purchase, group: group),
                ),
              );
            }
          }
        },
      ),
      floatingActionButtonLocation: settings.dominantHand == DominantHand.right
          ? FloatingActionButtonLocation.endFloat
          : settings.dominantHand == DominantHand.left
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.centerFloat,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 80),
            sliver: PurchasesList(stream: repo.watchPurchasesInGroup(group.id), group: group),
          ),
        ],
      ),
    );
  }
}
