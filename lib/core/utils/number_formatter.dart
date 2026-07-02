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
    return toString();
  }

  String toWeightString(String? unit) {
    if (this % 1 == 0) return '${toInt()}$unit';
    return '${toStringAsFixed(2)}$unit';
  }

  String toCurrencyString(String currencySymbol) {
    if (this % 1 == 0) return '$currencySymbol${toInt()}';
    return '$currencySymbol${toStringAsFixed(2)}';
  }
}
