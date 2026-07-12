import 'package:flutter/material.dart';
import 'package:shopping_assist/features/groups/views/screens/groups_screen.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';

class ShoppingApp extends StatelessWidget {
  const ShoppingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Cart Ops',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.seedColor,
          brightness: Brightness.light,
          surface: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.seedColor,
          brightness: Brightness.dark,
          surface: Colors.black,
        ),
      ),
      themeMode: settings.themeMode,
      home: const GroupsScreen(),
      debugShowCheckedModeBanner: false, // Yeet the annoying banner
    );
  }
}
