import 'package:intl/intl.dart';

extension NumberFormatting on double {
  /// Converts a double to a price string
  ///
  /// Example:
  /// 1.2345 -> "1.23"
  /// 1.001 -> "1.00"
  /// 1.0 -> "1"
  String toInputString() {
    if (this == truncateToDouble()) return truncate().toString();
    return toStringAsFixed(2);
  }

  /// Converts a double to a weight string
  ///
  /// Example:
  /// 1.2345 -> "1.2345kg"
  /// 1.30 -> "1.3kg"
  /// 1.0 -> "1kg"
  String toQuantityString(String? unit) {
    String unitStr = unit ?? '';
    if (this % 1 == 0) return '${toInt()}$unitStr';
    String value = toString();
    return '$value$unitStr';
  }

  /// Converts a double to a formatted currency string with commas
  ///
  /// Example:
  /// 1234.56 -> "$1,234.56"
  /// 1234.0 -> "$1,234" (when preferWhole is true)
  /// -1234.56 -> "-$1,234.56"
  String toCurrencyString(
    String currencySymbol, {
    bool preferWhole = false,
    String locale = 'en_US',
  }) {
    final isNegative = this < 0;
    final absValue = abs();
    final sign = isNegative ? '-' : '';
    NumberFormat formatter;
    try {
      formatter = NumberFormat.currency(
        locale: locale,
        symbol: currencySymbol,
        decimalDigits: preferWhole && absValue % 1 == 0 ? 0 : 2,
      );
    } catch (e) {
      formatter = NumberFormat.currency(
        locale: 'en_US',
        symbol: currencySymbol,
        decimalDigits: preferWhole && absValue % 1 == 0 ? 0 : 2,
      );
    }
    String formatted = formatter.format(absValue);
    String numberPart = formatted.replaceAll(currencySymbol, '').trim();
    if (isNegative) return '$sign$currencySymbol$numberPart';
    return '$currencySymbol$numberPart';
  }
}
