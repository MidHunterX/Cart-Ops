import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';

void main() {
  late SettingsProvider settingsProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': 2, // Dark mode
      'currency_code': 'EUR',
    });
    final prefs = await SharedPreferences.getInstance();
    settingsProvider = SettingsProvider(prefs);
  });

  test('Initial settings load correctly from SharedPreferences', () {
    expect(settingsProvider.themeMode, ThemeMode.dark);
    expect(settingsProvider.currencyCode, 'EUR');
    expect(settingsProvider.currencySymbol, '€');
  });

  test('Updating ThemeMode notifies listeners and updates prefs', () async {
    settingsProvider.setThemeMode(ThemeMode.light);
    expect(settingsProvider.themeMode, ThemeMode.light);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('theme_mode'), ThemeMode.light.index);
  });
}
