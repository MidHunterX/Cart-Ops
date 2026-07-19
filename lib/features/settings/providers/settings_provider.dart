import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/settings_data.dart';

class SettingsProvider extends ChangeNotifier {
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
  Color _seedColor = Colors.blue;
  Color get seedColor => _seedColor;
  void setSeedColor(Color color) async {
    _seedColor = color;
    notifyListeners();
    _prefs.setInt(_colorKey, color.toARGB32());
  }

  // Compact Item List

  void _loadCompactItemList() {
    final compactItemList = _prefs.getBool(_compactItemListKey);
    if (compactItemList != null) _compactItemList = compactItemList;
  }

  static const String _compactItemListKey = 'compact_item_list';
  bool _compactItemList = true;
  bool get compactItemList => _compactItemList;
  void setCompactItemList(bool isCompact) async {
    _compactItemList = isCompact;
    notifyListeners();
    _prefs.setBool(_compactItemListKey, isCompact);
  }

  // Dominant Hand

  void _loadDominantHandSettings() {
    final dominantHand = _prefs.getString(_dominantHandKey);
    if (dominantHand != null) _dominantHand = dominantHand;
  }

  static const String _dominantHandKey = DominantHand.right;
  String _dominantHand = DominantHand.right;
  String get dominantHand => _dominantHand;
  void setFab(String fabLocation) async {
    _dominantHand = fabLocation;
    notifyListeners();
    _prefs.setString(_dominantHandKey, fabLocation);
  }

  // Calculator vs Telephone Keypad

  void _loadTelephoneSettings() {
    final isTelephone = _prefs.getBool(_telephoneLayoutKey);
    if (isTelephone != null) _useTelephoneLayout = isTelephone;
  }

  static const String _telephoneLayoutKey = 'use_telephone_layout';
  bool _useTelephoneLayout = false;
  bool get isTelephoneLayout => _useTelephoneLayout;
  void setTelephoneLayout(bool useCalculator) async {
    _useTelephoneLayout = useCalculator;
    notifyListeners();
    _prefs.setBool(_telephoneLayoutKey, useCalculator);
  }

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

  void _loadCurrencySettings() {
    final saved = _prefs.getString(_currencyKey);
    if (saved != null) {
      _currencyCode = saved;
      return;
    }

    // Detect from device locale
    Locale locale = WidgetsBinding.instance.platformDispatcher.locale;
    final countryCode = locale.countryCode;
    if (countryCode != null) {
      final detectedCurrency = getCurrencyByCountryCode(countryCode);
      if (detectedCurrency != null && currencies.any((c) => c.code == detectedCurrency.code)) {
        _currencyCode = detectedCurrency.code;
        return;
      }
    }

    _currencyCode = 'USD';
  }

  static const String _currencyKey = 'currency_code';
  String _currencyCode = 'USD';
  String get currencyCode => _currencyCode;
  String get currencySymbol => currencies.firstWhere((c) => c.code == currencyCode).symbol;
  void setCurrency(String code) async {
    _currencyCode = code;
    notifyListeners();
    _prefs.setString(_currencyKey, code);
  }

  // Groups Feture

  void _loadGroupSettings() {
    final isGroup = _prefs.getBool(_groupEnabledKey);
    if (isGroup != null) _useGroupLayout = isGroup;
  }

  static const String _groupEnabledKey = 'is_group_enabled';
  bool _useGroupLayout = false;
  bool get isGroupEnabled => _useGroupLayout;
  void setGroupFeatureStatus(bool useGroupFeature) async {
    _useGroupLayout = useGroupFeature;
    notifyListeners();
    _prefs.setBool(_groupEnabledKey, useGroupFeature);
  }

  // ======================================================================= //

  final SharedPreferences _prefs;

  SettingsProvider(this._prefs) {
    _loadThemeSettings();
    _loadColorSettings();
    _loadWeightSettings();
    _loadCurrencySettings();
    _loadCompactItemList();
    _loadDominantHandSettings();
    _loadTelephoneSettings();
    _loadGroupSettings();
  }
}

extension SettingsContext on BuildContext {
  SettingsProvider get settings => watch<SettingsProvider>();
  SettingsProvider get settingsRead => read<SettingsProvider>();

  String get currencySymbol => settings.currencySymbol;
  String get weightUnit => settings.weightUnit;
  String get currencyCode => settings.currencyCode;
  bool get isCompactItemList => settings.compactItemList;
  ThemeMode get themeMode => settings.themeMode;
  Color get seedColor => settings.seedColor;
  String get dominantHand => settings.dominantHand;
  bool get isTelephoneLayout => settings.isTelephoneLayout;
  bool get isGroupEnabled => settings.isGroupEnabled;
}
