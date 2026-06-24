import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import './widgets/theme_colorpicker_v2.dart';
import './widgets/section_header.dart';
import './widgets/currency_picker.dart';
import './widgets/theme_mode_selector.dart';

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
          const SettingsSectionHeader(title: 'Appearance'),

          ListTile(
            title: const Text('Theme Mode'),
            subtitle: Text(settings.themeMode.name.toUpperCase()),
            trailing: ThemeModeSelector(
              currentThemeMode: settings.themeMode,
              onThemeModeChanged: settings.setThemeMode,
            ),
          ),

          const Divider(),

          ListTile(
            title: const Text('Theme Color'),
            subtitle: ThemeColorPicker(
              selectedColor: settings.seedColor,
              onColorSelected: settings.setSeedColor,
            ),
          ),

          const Divider(),

          const SettingsSectionHeader(title: 'Localization'),

          ListTile(
            title: const Text('Currency'),
            subtitle: Text(settings.currencyCode),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () => showModalBottomSheet(
              context: context,
              builder: (context) {
                return CurrencyPicker(settings: settings);
              },
            ),
          ),
        ],
      ),
    );
  }
}
