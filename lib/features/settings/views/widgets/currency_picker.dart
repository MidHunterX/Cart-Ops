import 'package:flutter/material.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import '../../data/settings_data.dart';

class CurrencyPicker extends StatelessWidget {
  final SettingsProvider settings;

  const CurrencyPicker({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: currencies.length,
      itemBuilder: (context, index) {
        final currency = currencies[index];
        return ListTile(
          leading: Text(currency.flag, style: const TextStyle(fontSize: 24)),
          title: Text(currency.code),
          trailing: Text(
            currency.symbol,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: Text(currency.name),
          onTap: () {
            settings.setCurrency(currency.code);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
