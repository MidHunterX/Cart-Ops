extension NumberFormatting on double {
  /// Converts a double to a whole number string
  ///
  /// Example:
  /// 1.2345 -> "1.2345"
  /// 1.0 -> "1"
  String toWholeNumberString() {
    if (this == 0) return '0';
    if (this % 1 == 0) return toInt().toString();
    return toStringAsFixed(2);
  }

  /// Converts a double to a price string
  ///
  /// Example:
  /// 1.2345 -> "1.23"
  /// 1.0 -> "1.00"
  String toPriceString() {
    if (this == truncateToDouble()) return truncate().toString();
    return toStringAsFixed(2);
  }

  /// Converts a double to a weight string
  ///
  /// Example:
  /// 1.2345 -> "1.2345kg"
  /// 1.30 -> "1.3kg"
  /// 1.0 -> "1kg"
  String toWeightString(String? unit) {
    String unitStr = unit ?? '';
    if (this % 1 == 0) return '${toInt()}$unitStr';
    String value = toString();
    return '$value$unitStr';
  }

  String toCurrencyString(String currencySymbol, {bool preferWhole = false}) {
    final isNegative = this < 0;
    final absValue = abs();
    final sign = isNegative ? '-' : '';
    if (preferWhole && absValue % 1 == 0) return '$sign$currencySymbol${absValue.toInt()}';
    return '$sign$currencySymbol${absValue.toStringAsFixed(2)}';
  }
}
