import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/features/settings/data/settings_data.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import './widgets/theme_colorpicker_v2.dart';
import './widgets/section_header.dart';
import './widgets/currency_picker.dart';
import './widgets/theme_mode_selector.dart';
import './widgets/weight_unit_picker.dart';
import './widgets/fab_location_picker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), backgroundColor: colorScheme.primaryContainer),
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
              isScrollControlled: true, // makes sheet full screen
              builder: (context) {
                return CurrencyPicker(settings: settings);
              },
            ),
          ),

          ListTile(
            title: const Text('Weight Unit'),
            subtitle: Text(settings.weightUnit),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () => showModalBottomSheet(
              context: context,
              builder: (context) {
                return WeightUnitPicker(settings: settings);
              },
            ),
          ),

          const Divider(),

          const SettingsSectionHeader(title: 'Accessibility'),

          ListTile(
            title: const Text('Dynamic Item List'),
            subtitle: Text(
              settings.compactItemList ?? false ? 'Enabled (Compact)' : 'Disabled (Structured)',
            ),
            trailing: Switch(
              value: settings.compactItemList ?? false,
              onChanged: settings.setCompactItemList,
            ),
          ),

          ListTile(
            title: const Text('Dominant Hand'),
            subtitle: Text(settings.dominantHand ?? DominantHand.right),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () => showModalBottomSheet(
              context: context,
              builder: (context) {
                return FabLocationPicker(
                  currentLocation: settings.dominantHand,
                  onChanged: (newLocation) {
                    settings.setFab(newLocation);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
