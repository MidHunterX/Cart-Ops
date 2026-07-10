import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_assist/app.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/database/daos/groups_dao.dart';
import 'package:shopping_assist/core/database/daos/items_dao.dart';
import 'package:shopping_assist/core/database/daos/purchased_items_dao.dart';
import 'package:shopping_assist/core/database/daos/purchases_dao.dart';
import 'package:shopping_assist/features/groups/repositories/groups_repository.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';
import 'package:shopping_assist/features/purchased_items/repositories/purchased_items_repository.dart';
import 'package:shopping_assist/features/purchases/repositories/purchases_repository.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
// import 'package:shopping_assist/dev/generate_seeds.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // ======================= UNCOMMENT TO SEED DATABASE =======================
  // final db = AppDatabase();
  // final seeder = DatabaseSeeder(
  //   db,
  //   config: const SeederConfig(
  //     numGroups: 2,
  //     maxPurchasesPerGroup: 40,
  //     numOrphanPurchases: 30,
  //   )
  // );
  // await seeder.seed();
  // ==========================================================================

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
        Provider<AppDatabase>(create: (_) => AppDatabase(), dispose: (_, db) => db.close()),

        // Provide DAOs directly
        Provider<GroupsDao>(create: (context) => context.read<AppDatabase>().groupsDao),
        Provider<ItemsDao>(create: (context) => context.read<AppDatabase>().itemsDao),
        Provider<PurchasesDao>(create: (context) => context.read<AppDatabase>().purchasesDao),
        Provider<PurchasedItemsDao>(
          create: (context) => context.read<AppDatabase>().purchasedItemsDao,
        ),

        // Repositories should depend on DAOs only
        ProxyProvider<GroupsDao, GroupsRepository>(
          update: (_, groupsDao, _) => GroupsRepository(groupsDao),
        ),
        ProxyProvider<ItemsDao, ItemsRepository>(
          update: (_, itemsDao, _) => ItemsRepository(itemsDao),
        ),
        ProxyProvider<PurchasesDao, PurchasesRepository>(
          update: (_, purchasesDao, _) => PurchasesRepository(purchasesDao),
        ),
        ProxyProvider3<ItemsDao, PurchasedItemsDao, PurchasesDao, PurchasedItemsRepository>(
          update: (_, itemsDao, purchasedItemsDao, purchasesDao, _) =>
              PurchasedItemsRepository(purchasedItemsDao, itemsDao, purchasesDao),
        ),
      ],
      child: const ShoppingApp(),
    ),
  );
}
