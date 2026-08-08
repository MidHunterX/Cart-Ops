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

  // Compact Price Input

  void _loadCompactPriceInput() {
    final compactPriceInput = _prefs.getBool(_compactPriceInputKey);
    if (compactPriceInput != null) _compactPriceInput = compactPriceInput;
  }

  static const String _compactPriceInputKey = 'compact_price_input';
  bool _compactPriceInput = true;
  bool get compactPriceInput => _compactPriceInput;
  void setCompactPriceInput(bool isCompact) async {
    _compactPriceInput = isCompact;
    notifyListeners();
    _prefs.setBool(_compactPriceInputKey, isCompact);
  }

  // Dominant Hand

  void _loadDominantHandSettings() {
    final dominantHand = _prefs.getString(_dominantHandKey);
    if (dominantHand != null) _dominantHand = dominantHand;
  }

  static const String _dominantHandKey = 'dominant_hand';
  String _dominantHand = DominantHand.right;
  String get dominantHand => _dominantHand;
  void setFab(String fabLocation) async {
    _dominantHand = fabLocation;
    notifyListeners();
    _prefs.setString(_dominantHandKey, fabLocation);
  }

  // KEYPAD LAYOUT SETTINGS

  void _loadKeypadSettings() {
    final isTelephone = _prefs.getBool(_telephoneLayoutKey);
    if (isTelephone != null) _useTelephoneLayout = isTelephone;

    final isAltInfo = _prefs.getBool(_altInfoLayoutKey);
    if (isAltInfo != null) _useAltInfoLayout = isAltInfo;
  }

  static const String _telephoneLayoutKey = 'use_telephone_layout';
  bool _useTelephoneLayout = false;
  bool get isTelephoneLayout => _useTelephoneLayout;
  void setTelephoneLayout(bool useCalculator) async {
    _useTelephoneLayout = useCalculator;
    notifyListeners();
    _prefs.setBool(_telephoneLayoutKey, useCalculator);
  }

  static const String _altInfoLayoutKey = 'use_alt_info_layout';
  bool _useAltInfoLayout = false;
  bool get isAltInfoLayout => _useAltInfoLayout;
  void setAltInfoLayout(bool useAltInfoLayout) async {
    _useAltInfoLayout = useAltInfoLayout;
    notifyListeners();
    _prefs.setBool(_altInfoLayoutKey, useAltInfoLayout);
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
  String get currencyLocale {
    final currency = currencies.firstWhere(
      (c) => c.code == currencyCode,
      orElse: () => currencies.first,
    );
    if (currency.code == 'EUR') return 'de_DE';
    if (currency.code == 'BRL') return 'pt_BR';
    if (currency.code == 'RUB') return 'ru_RU';
    if (currency.code == 'IDR') return 'id_ID';
    if (currency.code == 'TRY') return 'tr_TR';
    if (currency.code == 'VND') return 'vi_VN';
    if (currency.countryCode != null) return 'en_${currency.countryCode}';
    return 'en_US';
  }

  bool get isCurrencyDefault => _prefs.getString(_currencyKey) == null;

  void setCurrency(String code) async {
    _currencyCode = code;
    notifyListeners();
    _prefs.setString(_currencyKey, code);
  }

  void clearCurrency() async {
    await _prefs.remove(_currencyKey);
    _loadCurrencySettings();
    notifyListeners();
  }

  // FEATURE SETTINGS

  void _loadFeatureSettings() {
    final isGroup = _prefs.getBool(_groupEnabledKey);
    if (isGroup != null) _useGroupLayout = isGroup;

    final isManualItem = _prefs.getBool(_manualItemEnabledKey);
    if (isManualItem != null) _useManualItem = isManualItem;
  }

  static const String _groupEnabledKey = 'is_group_enabled';
  bool _useGroupLayout = false;
  bool get isGroupEnabled => _useGroupLayout;
  void setGroupFeatureStatus(bool useGroupFeature) async {
    _useGroupLayout = useGroupFeature;
    notifyListeners();
    _prefs.setBool(_groupEnabledKey, useGroupFeature);
  }

  static const String _manualItemEnabledKey = 'is_manual_item_enabled';
  bool _useManualItem = false;
  bool get isManualItemEnabled => _useManualItem;
  void setManualItemFeatureStatus(bool useManualItemFeature) async {
    _useManualItem = useManualItemFeature;
    notifyListeners();
    _prefs.setBool(_manualItemEnabledKey, useManualItemFeature);
  }

  // ======================================================================= //

  final SharedPreferences _prefs;

  SettingsProvider(this._prefs) {
    _loadThemeSettings();
    _loadColorSettings();
    _loadWeightSettings();
    _loadCurrencySettings();
    _loadCompactItemList();
    _loadCompactPriceInput();
    _loadDominantHandSettings();
    _loadKeypadSettings();
    _loadFeatureSettings();
  }
}

extension SettingsContext on BuildContext {
  SettingsProvider get settings => watch<SettingsProvider>();
  SettingsProvider get settingsRead => read<SettingsProvider>();

  String get currencySymbol => settings.currencySymbol;
  String get currencyLocale => settings.currencyLocale;
  String get weightUnit => settings.weightUnit;
  String get currencyCode => settings.currencyCode;
  bool get isCompactItemList => settings.compactItemList;
  bool get isCompactPriceInput => settings.compactPriceInput;
  ThemeMode get themeMode => settings.themeMode;
  Color get seedColor => settings.seedColor;
  String get dominantHand => settings.dominantHand;
  bool get isTelephoneLayout => settings.isTelephoneLayout;
  bool get isAltInfoLayout => settings.isAltInfoLayout;
  bool get isGroupEnabled => settings.isGroupEnabled;
  bool get isManualItemEnabled => settings.isManualItemEnabled;
}
