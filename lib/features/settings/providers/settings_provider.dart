import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/settings_data.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _colorKey = 'seed_color';
  static const String _currencyKey = 'currency_code';

  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = Colors.greenAccent;
  String _currencyCode = 'USD';

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  String get currencyCode => _currencyCode;
  String get currencySymbol => currencies.firstWhere((c) => c.code == currencyCode).symbol;

  final SharedPreferences _prefs;

  SettingsProvider(this._prefs) {
    _loadSettings();
  }

  void _loadSettings() {
    final themeIndex = _prefs.getInt(_themeKey);
    if (themeIndex != null) _themeMode = ThemeMode.values[themeIndex];

    final colorValue = _prefs.getInt(_colorKey);
    if (colorValue != null) _seedColor = Color(colorValue);

    _currencyCode = _prefs.getString(_currencyKey) ?? 'USD';
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_themeKey, mode.index);
  }

  void setSeedColor(Color color) async {
    _seedColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_colorKey, color.toARGB32());
  }

  void setCurrency(String code) async {
    _currencyCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_currencyKey, code);
  }
}
