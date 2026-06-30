import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/app.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/features/groups/repositories/groups_repository.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';
import 'package:shopping_assist/features/purchased_items/repositories/purchased_items_repository.dart';
import 'package:shopping_assist/features/purchases/repositories/purchases_repository.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        Provider<AppDatabase>(
          create: (_) => AppDatabase(),
          dispose: (_, db) => db.close(),
        ),
        ProxyProvider<AppDatabase, GroupsRepository>(
          update: (_, db, _) => GroupsRepository(db),
        ),
        ProxyProvider<AppDatabase, ItemsRepository>(
          update: (_, db, _) => ItemsRepository(db),
        ),
        ProxyProvider<AppDatabase, PurchasesRepository>(
          update: (_, db, _) => PurchasesRepository(db),
        ),
        ProxyProvider2<AppDatabase, ItemsRepository, PurchasedItemsRepository>(
          update: (_, db, itemsRepo, _) => PurchasedItemsRepository(db, itemsRepo),
        ),
      ],
      child: const ShoppingApp(),
    ),
  );
}
