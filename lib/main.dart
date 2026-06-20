import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/app.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/features/groups/repositories/groups_repository.dart';
import 'package:shopping_assist/features/purchased_items/repositories/purchased_items_repository.dart';
import 'package:shopping_assist/features/purchases/repositories/purchases_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>(
          create: (_) => AppDatabase(),
          dispose: (_, db) => db.close(),
        ),
        ProxyProvider<AppDatabase, GroupsRepository>(
          update: (_, db, _) => GroupsRepository(db),
        ),
        ProxyProvider<AppDatabase, PurchasesRepository>(
          update: (_, db, _) => PurchasesRepository(db),
        ),
        ProxyProvider<AppDatabase, PurchasedItemsRepository>(
          update: (_, db, _) => PurchasedItemsRepository(db),
        ),
      ],
      child: const ShoppingApp(),
    ),
  );
}
