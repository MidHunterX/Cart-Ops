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
          ),

          SettingCard(
            title: 'Weight Unit',
            subtitle: context.weightUnit,
            onTap: () => showModalBottomSheet(
              context: context,
              showDragHandle: true,
              builder: (_) => const WeightUnitPicker(),
            ),
          ),

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

          SettingCard(
            title: 'Item Creation',
            subtitle: context.isManualItemEnabled
                ? 'Enabled (Option to add items unlocked)'
                : 'Disabled (Automatic only)',
            control: Switch(
              value: context.isManualItemEnabled,
              onChanged: settings.setManualItemFeatureStatus,
            ),
          ),

          const SettingsSectionHeader(
            title: 'Accessibility & Layout',
            icon: Icons.accessibility_new,
          ),

          SettingCard(
            title: 'Dynamic Item List',
            subtitle: context.isCompactItemList
                ? 'Enabled (Compact rows)'
                : 'Disabled (Structured rows)',
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
            isModalSheet: true,
            title: 'Compact Price Input',
            subtitle: context.isCompactPriceInput
                ? 'Enabled (Modal Calculator)'
                : 'Disabled (Inline Total Field)',
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
            isModalSheet: true,
            title: 'Alternate Info Layout',
            subtitle: context.isAltInfoLayout ? 'Enabled (Stacked)' : 'Disabled (Side‑by‑side)',
            control: Switch(value: context.isAltInfoLayout, onChanged: settings.setAltInfoLayout),
            wireframe: _AltInfoLayoutWireframe(isAltInfo: context.isAltInfoLayout),
          ),

          SettingCard(
            isModalSheet: true,
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

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ========================================================================= //

const double _quantity = 69.0;
const double _unitPrice = 420.0;
const double _unitPriceAfterDiscount = 419.0;
const double _totalPrice = 28980.0;
const double _totalPriceAfterDiscount = 28911.03;
const double _discountedPrice = -68.97;

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
                child: _buildInputField(
                  context,
                  label: 'Quantity',
                  value: _quantity.toInputString(),
                  isActive: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 8,
                child: _buildInputField(
                  context,
                  label: 'Listing Price',
                  value: _unitPrice.toInputString(),
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
                child: _buildInputField(
                  context,
                  label: 'Quantity',
                  value: _quantity.toInputString(),
                  isActive: false,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 4,
                child: _buildInputField(
                  context,
                  label: 'Unit Price',
                  value: _unitPrice.toInputString(),
                  isActive: true,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 4,
                child: _buildInputField(
                  context,
                  label: 'Total',
                  value: _totalPrice.toInputString(),
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

    return Material(
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // QUANTITY SECTION
                SizedBox(
                  width: 60,
                  child: isCompact
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _quantity.toQuantityString(null),
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              'Units',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _quantity.toQuantityString(null),
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              'Units',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 8),

                // IMAGE SECTION
                !isCompact
                    ? Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          size: 30,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    : const SizedBox.shrink(),

                const SizedBox(width: 8),

                // ITEM DETAILS SECTION
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      !isCompact
                          ? Text(
                              '--',
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          : const SizedBox.shrink(),
                      Wrap(
                        spacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _unitPrice.toCurrencyString(currencySymbol, preferWhole: true),
                            style: !isCompact
                                ? Theme.of(context).textTheme.bodySmall?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: colorScheme.onSurfaceVariant,
                                  )
                                : Theme.of(context).textTheme.titleMedium?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                          ),
                          Text(
                            _unitPriceAfterDiscount.toCurrencyString(
                              currencySymbol,
                              locale: context.currencyLocale,
                            ),
                            style: !isCompact
                                ? Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  )
                                : Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // TOTAL PRICE SECTION
                SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _totalPriceAfterDiscount.toCurrencyString(
                            currencySymbol,
                            locale: context.currencyLocale,
                          ),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _discountedPrice.toCurrencyString(
                            currencySymbol,
                            locale: context.currencyLocale,
                          ),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                Icon(Icons.more_vert, size: 24, color: colorScheme.onSurfaceVariant),
              ],
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

class _AltInfoLayoutWireframe extends StatelessWidget {
  final bool isAltInfo;
  const _AltInfoLayoutWireframe({required this.isAltInfo});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: isAltInfo
          ? Row(
              children: [
                Expanded(child: _buildIconBtn(context, Icons.image)),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildActionBtn(context, text: 'Some Name Here', isActive: true),
                      ),
                      const SizedBox(height: 4),
                      Expanded(child: _buildActionBtn(context, text: 'Discount', isActive: false)),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(child: _buildIconBtn(context, Icons.keyboard_tab)),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildIconBtn(context, Icons.image)),
                const SizedBox(width: 6),
                Expanded(child: _buildActionBtn(context, text: 'Some Name Here', isActive: true)),
                const SizedBox(width: 6),
                Expanded(child: _buildActionBtn(context, text: 'Discount', isActive: false)),
                const SizedBox(width: 6),
                Expanded(child: _buildIconBtn(context, Icons.keyboard_tab)),
              ],
            ),
    );
  }

  Widget _buildActionBtn(BuildContext context, {required String text, required bool isActive}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: isActive ? colorScheme.primaryContainer : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            overflow: TextOverflow.ellipsis,
            fontWeight: FontWeight.bold,
            color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildIconBtn(BuildContext context, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: colorScheme.onSurfaceVariant, size: 24),
    );
  }
}
