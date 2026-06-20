import 'package:flutter/material.dart';
import 'package:shopping_assist/app.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    Provider<AppDatabase>(
      create: (context) => AppDatabase(),
      dispose: (context, db) => db.close(),
      child: const ShoppingApp(),
    ),
  );
}
