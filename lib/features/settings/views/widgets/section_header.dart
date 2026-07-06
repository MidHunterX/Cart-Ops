import 'package:flutter/material.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;

  const SettingsSectionHeader({super.key, required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null ? Icon(icon) : null,
      title: Text(
        title.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
