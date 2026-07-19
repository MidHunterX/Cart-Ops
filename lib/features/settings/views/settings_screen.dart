import 'package:flutter/material.dart';
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
    final settings = context.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: 'Appearance', icon: Icons.color_lens),

          ListTile(
            title: const Text('Theme Mode'),
            subtitle: Text(context.themeMode.name.toUpperCase()),
            trailing: ThemeModeSelector(
              currentThemeMode: context.themeMode,
              onThemeModeChanged: settings.setThemeMode,
            ),
          ),

          ListTile(
            title: const Text('Theme Color'),
            subtitle: ThemeColorPicker(
              selectedColor: context.seedColor,
              onColorSelected: settings.setSeedColor,
            ),
          ),

          const Divider(),

          const SettingsSectionHeader(title: 'Localization', icon: Icons.language),

          ListTile(
            title: const Text('Currency'),
            subtitle: Text(context.currencyCode),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              showDragHandle: true,
              builder: (context) {
                return const CurrencyPicker();
              },
            ),
          ),

          ListTile(
            title: const Text('Weight Unit'),
            subtitle: Text(context.weightUnit),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () => showModalBottomSheet(
              context: context,
              showDragHandle: true,
              builder: (context) {
                return const WeightUnitPicker();
              },
            ),
          ),

          const Divider(),

          const SettingsSectionHeader(title: 'Features', icon: Icons.widgets),

          SwitchListTile(
            title: const Text('Purchase Groups'),
            subtitle: Text(context.isGroupEnabled ? 'Enabled' : 'Disabled'),
            value: context.isGroupEnabled,
            onChanged: settings.setGroupFeatureStatus,
          ),

          const Divider(),

          const SettingsSectionHeader(title: 'Accessibility', icon: Icons.accessibility_new),

          SwitchListTile(
            title: const Text('Dynamic Item List'),
            subtitle: Text(
              context.isCompactItemList ? 'Enabled (Compact)' : 'Disabled (Structured)',
            ),
            value: context.isCompactItemList,
            onChanged: settings.setCompactItemList,
          ),

          ListTile(
            title: const Text('Dominant Hand'),
            subtitle: Text(context.dominantHand),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () => showModalBottomSheet(
              context: context,
              showDragHandle: true,
              builder: (context) {
                return FabLocationPicker(
                  currentLocation: context.dominantHand,
                  onChanged: (newLocation) {
                    settings.setFab(newLocation);
                  },
                );
              },
            ),
          ),

          ListTile(
            title: const Text('Keypad Layout'),
            subtitle: Text(context.isTelephoneLayout ? 'Telephone Style' : 'Calculator Style'),
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
              selected: {context.isTelephoneLayout ? 'telephone' : 'calculator'},
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
