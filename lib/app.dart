import 'package:flutter/material.dart';
import 'package:shopping_assist/features/groups/views/screens/groups_screen.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';

class ShoppingApp extends StatelessWidget {
  const ShoppingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cart Ops',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: context.seedColor,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: context.seedColor,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: context.themeMode,
      home: const GroupsScreen(),
      debugShowCheckedModeBanner: false, // Yeet the annoying banner
    );
  }
}
