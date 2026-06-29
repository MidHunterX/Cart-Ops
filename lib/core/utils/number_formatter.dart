extension NumberFormatting on double {
  String toWholeNumberString() {
    if (this == 0) return '0';
    if (this % 1 == 0) return toInt().toString();
    return toStringAsFixed(2);
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
