import 'package:flutter/material.dart';
import 'package:shopping_assist/features/groups/views/screens/groups_screen.dart';

class ShoppingApp extends StatelessWidget {
  const ShoppingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopping Assist',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green)),
      home: const GroupsScreen(),
    );
  }
}
