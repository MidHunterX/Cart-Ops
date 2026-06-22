import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import '../data/settings_data.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colorScheme.primaryContainer,
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text(
              'Appearance',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          ListTile(
            title: const Text('Theme Mode'),
            subtitle: Text(settings.themeMode.name.toUpperCase()),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.settings_brightness),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (set) => settings.setThemeMode(set.first),
            ),
          ),

          ListTile(
            title: const Text('Theme Color'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 12,
                children: colorOptions.map((color) {
                  return GestureDetector(
                    onTap: () => settings.setSeedColor(color),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: CircleAvatar(
                        backgroundColor: color,
                        radius: 20,
                        child: settings.seedColor == color
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.black,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(),
          const ListTile(
            title: Text(
              'Localization',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          ListTile(
            title: const Text('Currency'),
            subtitle: Text(settings.currencySymbol),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () => _showCurrencyPicker(context, settings),
          ),
        ],
      ),
    );
  }
}

void _showCurrencyPicker(BuildContext context, SettingsProvider settings) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return ListView.builder(
        itemCount: currencies.length,
        itemBuilder: (context, index) {
          final currency = currencies[index];
          return ListTile(
            leading: Text(currency.flag, style: const TextStyle(fontSize: 24)),
            title: Text('${currency.symbol} - ${currency.code}'),
            subtitle: Text(currency.name),
            onTap: () {
              settings.setCurrency(currency.code);
              Navigator.pop(context);
            },
          );
        },
      );
    },
  );
}
