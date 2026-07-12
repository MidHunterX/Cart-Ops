import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: 'Appearance', icon: Icons.color_lens),

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

          const SettingsSectionHeader(title: 'Localization', icon: Icons.language),

          ListTile(
            title: const Text('Currency'),
            subtitle: Text(settings.currencyCode),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              showDragHandle: true,
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
              showDragHandle: true,
              builder: (context) {
                return WeightUnitPicker(settings: settings);
              },
            ),
          ),

          const Divider(),

          const SettingsSectionHeader(title: 'Accessibility', icon: Icons.accessibility_new),

          SwitchListTile(
            title: const Text('Dynamic Item List'),
            subtitle: Text(
              settings.compactItemList ? 'Enabled (Compact)' : 'Disabled (Structured)',
            ),
            value: settings.compactItemList,
            onChanged: settings.setCompactItemList,
          ),

          ListTile(
            title: const Text('Dominant Hand'),
            subtitle: Text(settings.dominantHand),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () => showModalBottomSheet(
              context: context,
              showDragHandle: true,
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

          ListTile(
            title: const Text('Keypad Layout'),
            subtitle: Text(settings.isTelephoneLayout ? 'Telephone Style' : 'Calculator Style'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'calculator',
                  label: Text('Calc'),
                  icon: Icon(Icons.calculate),
                ),
                ButtonSegment(
                  value: 'telephone',
                  label: Text('Phone'),
                  icon: Icon(Icons.phone_android),
                ),
              ],
              selected: {settings.isTelephoneLayout ? 'telephone' : 'calculator'},
              onSelectionChanged: (Set<String> newSelection) {
                final newValue = newSelection.first;
                settings.setTelephoneLayout(newValue == 'telephone');
              },
            ),
          ),
        ],
      ),
    );
  }
}
