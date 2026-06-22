import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _colorKey = 'seed_color';
  static const String _currencyKey = 'currency_symbol';

  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = Colors.greenAccent;
  String _currencySymbol = '\$';

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  String get currencySymbol => _currencySymbol;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Theme Mode
    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null) _themeMode = ThemeMode.values[themeIndex];

    // Load Color
    final colorValue = prefs.getInt(_colorKey);
    if (colorValue != null) _seedColor = Color(colorValue);

    // Load Currency
    _currencySymbol = prefs.getString(_currencyKey) ?? '\$';

    notifyListeners();
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

  void setCurrency(String symbol) async {
    _currencySymbol = symbol;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_currencyKey, symbol);
  }
}
