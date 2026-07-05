import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/settings_data.dart';

class SettingsProvider extends ChangeNotifier {
  // ▄▀█ █▀█ █▀█ █▀▀ ▄▀█ █▀█ ▄▀█ █▄░█ █▀▀ █▀▀
  // █▀█ █▀▀ █▀▀ ██▄ █▀█ █▀▄ █▀█ █░▀█ █▄▄ ██▄

  // Lightmode | System | Darkmode

  void _loadThemeSettings() {
    final themeIndex = _prefs.getInt(_themeKey);
    if (themeIndex != null) _themeMode = ThemeMode.values[themeIndex];
  }

  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    _prefs.setInt(_themeKey, mode.index);
  }

  // Colorscheme

  void _loadColorSettings() {
    final colorValue = _prefs.getInt(_colorKey);
    if (colorValue != null) _seedColor = Color(colorValue);
  }

  static const String _colorKey = 'seed_color';
  Color _seedColor = Colors.greenAccent;
  Color get seedColor => _seedColor;
  void setSeedColor(Color color) async {
    _seedColor = color;
    notifyListeners();
    _prefs.setInt(_colorKey, color.toARGB32());
  }

  // Item Image Placeholder

  void _loadItemImageSettings() => _itemImagePlaceholder = _prefs.getBool(_itemImagePlaceholderKey);

  static const String _itemImagePlaceholderKey = 'item_image_placeholder';
  bool? _itemImagePlaceholder;
  bool? get itemImagePlaceholder => _itemImagePlaceholder;
  void setItemImagePlaceholder(bool? isPlaceholder) async {
    _itemImagePlaceholder = isPlaceholder;
    notifyListeners();
    _prefs.setBool(_itemImagePlaceholderKey, isPlaceholder ?? false);
  }

  // █░░ █▀█ █▀▀ ▄▀█ █░░ █ ▀█ ▄▀█ ▀█▀ █ █▀█ █▄░█
  // █▄▄ █▄█ █▄▄ █▀█ █▄▄ █ █▄ █▀█ ░█░ █ █▄█ █░▀█

  // Weight Unit

  void _loadWeightSettings() => _weightUnit = _prefs.getString(_weightUnitKey) ?? 'kg';

  static const String _weightUnitKey = 'weight_unit';
  String _weightUnit = 'kg';
  String get weightUnit => _weightUnit;
  void setWeightUnit(String unit) async {
    _weightUnit = unit;
    notifyListeners();
    _prefs.setString(_weightUnitKey, unit);
  }

  // Currency

  void _loadCurrencySettings() => _currencyCode = _prefs.getString(_currencyKey) ?? 'USD';

  static const String _currencyKey = 'currency_code';
  String _currencyCode = 'USD';
  String get currencyCode => _currencyCode;
  String get currencySymbol => currencies.firstWhere((c) => c.code == currencyCode).symbol;
  void setCurrency(String code) async {
    _currencyCode = code;
    notifyListeners();
    _prefs.setString(_currencyKey, code);
  }

  // ======================================================================= //

  final SharedPreferences _prefs;

  SettingsProvider(this._prefs) {
    _loadThemeSettings();
    _loadColorSettings();
    _loadWeightSettings();
    _loadCurrencySettings();
    _loadItemImageSettings();
  }
}
