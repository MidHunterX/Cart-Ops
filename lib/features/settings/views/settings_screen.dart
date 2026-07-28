import 'package:flutter/material.dart';
import 'package:shopping_assist/core/utils/number_formatter.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import 'widgets/currency_picker.dart';
import 'widgets/fab_location_picker.dart';
import 'widgets/section_header.dart';
import 'widgets/theme_colorpicker_v2.dart';
import 'widgets/theme_mode_selector.dart';
import 'widgets/weight_unit_picker.dart';
import 'widgets/settings_card.dart';
import '../data/settings_data.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          const SettingsSectionHeader(title: 'Appearance', icon: Icons.color_lens),

          SettingCard(
            title: 'Theme Mode',
            subtitle: context.themeMode.name.toUpperCase(),
            control: ThemeModeSelector(
              currentThemeMode: context.themeMode,
              onThemeModeChanged: settings.setThemeMode,
            ),
          ),

          SettingCard(
            title: 'Theme Color',
            subtitle: 'Accent & System Color Seed',
            bigControl: ThemeColorPicker(
              selectedColor: context.seedColor,
              onColorSelected: settings.setSeedColor,
            ),
          ),

          const SizedBox(height: 16),
          const SettingsSectionHeader(title: 'Localization', icon: Icons.language),

          SettingCard(
            title: 'Currency',
            subtitle: context.settings.isCurrencyDefault
                ? 'Default (${context.currencyCode})'
                : context.currencyCode,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              showDragHandle: true,
              builder: (_) => const CurrencyPicker(),
            ),
            wireframe: _CurrencyWireframe(currencySymbol: context.currencySymbol),
          ),

          SettingCard(
            title: 'Weight Unit',
            subtitle: context.weightUnit,
            onTap: () => showModalBottomSheet(
              context: context,
              showDragHandle: true,
              builder: (_) => const WeightUnitPicker(),
            ),
            wireframe: _WeightUnitWireframe(unit: context.weightUnit),
          ),

          const SizedBox(height: 16),
          const SettingsSectionHeader(title: 'Features', icon: Icons.widgets),

          SettingCard(
            title: 'Purchase Groups',
            subtitle: context.isGroupEnabled
                ? 'Enabled (Organized folders & purchases)'
                : 'Disabled (Direct purchases list)',
            control: Switch(
              value: context.isGroupEnabled,
              onChanged: settings.setGroupFeatureStatus,
            ),
          ),

          const SizedBox(height: 16),
          const SettingsSectionHeader(
            title: 'Accessibility & Layout',
            icon: Icons.accessibility_new,
          ),

          SettingCard(
            title: 'Dynamic Item List',
            subtitle: context.isCompactItemList
                ? 'Enabled (Compact rows, hide missing image box)'
                : 'Disabled (Structured rows, explicit image box)',
            control: Switch(
              value: context.isCompactItemList,
              onChanged: settings.setCompactItemList,
            ),
            wireframe: _DynamicItemListWireframe(
              isCompact: context.isCompactItemList,
              currencySymbol: context.currencySymbol,
            ),
          ),

          SettingCard(
            title: 'Compact Price Input',
            subtitle: context.isCompactPriceInput
                ? 'Enabled (2-Field layout with calculator)'
                : 'Disabled (3-Field inline total layout)',
            control: Switch(
              value: context.isCompactPriceInput,
              onChanged: settings.setCompactPriceInput,
            ),
            wireframe: _CompactPriceInputWireframe(
              isCompact: context.isCompactPriceInput,
              currencySymbol: context.currencySymbol,
            ),
          ),

          SettingCard(
            title: 'Dominant Hand',
            subtitle: 'FAB Placement: ${context.dominantHand.toUpperCase()}',
            onTap: () => showModalBottomSheet(
              context: context,
              showDragHandle: true,
              builder: (_) => FabLocationPicker(
                currentLocation: context.dominantHand,
                onChanged: settings.setFab,
              ),
            ),
            wireframe: _DominantHandWireframe(position: context.dominantHand),
          ),

          SettingCard(
            title: 'Keypad Layout',
            subtitle: context.isTelephoneLayout
                ? 'Telephone Style (1-2-3 top)'
                : 'Calculator Style (7-8-9 top)',
            control: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'calculator',
                  label: Text('Calc'),
                  icon: Icon(Icons.calculate, size: 16),
                ),
                ButtonSegment(
                  value: 'telephone',
                  label: Text('Phone'),
                  icon: Icon(Icons.phone_android, size: 16),
                ),
              ],
              selected: {context.isTelephoneLayout ? 'telephone' : 'calculator'},
              onSelectionChanged: (Set<String> newSelection) {
                settings.setTelephoneLayout(newSelection.first == 'telephone');
              },
            ),
            wireframe: _KeypadLayoutWireframe(isTelephone: context.isTelephoneLayout),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ========================================================================= //

class _CurrencyWireframe extends StatelessWidget {
  final String currencySymbol;
  const _CurrencyWireframe({required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 13, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Sample Total:',
                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          Text(
            1245678.69.toCurrencyString(currencySymbol),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightUnitWireframe extends StatelessWidget {
  final String unit;
  const _WeightUnitWireframe({required this.unit});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.scale_outlined, size: 13, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Item Weight:',
                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          Text(
            '2.50 $unit',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactPriceInputWireframe extends StatelessWidget {
  final bool isCompact;
  final String currencySymbol;
  const _CompactPriceInputWireframe({required this.isCompact, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    return isCompact
        ? Row(
            children: [
              Expanded(
                flex: 5,
                child: _buildInputField(context, label: 'Qty', value: '1', isActive: false),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 8,
                child: _buildInputField(
                  context,
                  label: 'Listing Price',
                  value: '$currencySymbol 12.00',
                  isActive: true,
                  suffixIcon: Icons.calculate_outlined,
                ),
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildInputField(context, label: 'Qty', value: '1', isActive: false),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 4,
                child: _buildInputField(
                  context,
                  label: 'Unit Price',
                  value: '$currencySymbol 12.00',
                  isActive: true,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 4,
                child: _buildInputField(
                  context,
                  label: 'Total',
                  value: '$currencySymbol 12.00',
                  isActive: false,
                ),
              ),
            ],
          );
  }

  Widget _buildInputField(
    BuildContext context, {
    required String label,
    required String value,
    required bool isActive,
    IconData? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: isActive ? colorScheme.primaryContainer : Colors.transparent,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isActive ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (suffixIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    suffixIcon,
                    color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: isActive ? colorScheme.primary : colorScheme.outline,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicItemListWireframe extends StatelessWidget {
  final bool isCompact;
  final String currencySymbol;
  const _DynamicItemListWireframe({required this.isCompact, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(8),
      child: isCompact
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '2x',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Wireless Mouse',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  '$currencySymbol 25.00',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.image, size: 16, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wireless Mouse',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Qty: 2  •  Unit: $currencySymbol 12.50',
                        style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$currencySymbol 25.00',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
    );
  }
}

class _DominantHandWireframe extends StatelessWidget {
  final String position;
  const _DominantHandWireframe({required this.position});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isLeft = position == DominantHand.left;
    final isCenter = position == DominantHand.center;

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 100,
              height: 6,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Align(
            alignment: isLeft
                ? Alignment.bottomLeft
                : isCenter
                ? Alignment.bottomCenter
                : Alignment.bottomRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_shopping_cart, size: 12, color: colorScheme.onPrimaryContainer),
                  const SizedBox(width: 4),
                  Text(
                    'Add Purchase',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeypadLayoutWireframe extends StatelessWidget {
  final bool isTelephone;
  const _KeypadLayoutWireframe({required this.isTelephone});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final keys = isTelephone
        ? [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['.99', '0', '.'],
          ]
        : [
            ['7', '8', '9'],
            ['4', '5', '6'],
            ['1', '2', '3'],
            ['.99', '0', '.'],
          ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              return Container(
                width: 32,
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Center(
                  child: Text(
                    key,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
