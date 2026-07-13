import 'package:flutter/material.dart';
import 'package:shopping_assist/core/database/database.dart';

/// Calculates the maximum number of data points that can fit in the available
/// chart width based on the longest price label and the provided constraints.
///
/// [context] is required for MediaQuery.
/// [history] is the full list of purchased items with purchase data.
/// [maxWidth] clamps the available width (e.g., 640 for modal sheets).
/// [horizontalPadding] is the total horizontal padding around the chart.
/// [labelFontSize] is the font size used for the price labels.
/// [extraLetters] pads the label width to account for extra letters.
int calculateMaxDataPoints(
  BuildContext context,
  List<PurchasedItemWithPurchase> history, {
  double maxWidth = double.infinity,
  double horizontalPadding = 8.0,
  double labelFontSize = 10.0,
  int extraLetters = 0,
}) {
  final double currentWidth = MediaQuery.of(context).size.width.clamp(0, maxWidth);
  final double labelWidth = _estimateLabelWidth(history, labelFontSize, extraLetters: extraLetters);
  final double minSpacing = labelWidth; // becase labels are evenly spaced

  final availableWidth = currentWidth - (horizontalPadding * 2);
  int calculatedMax = (availableWidth / (minSpacing + labelWidth)).floor();
  return calculatedMax.clamp(2, history.length);
}

/// Estimates the width of the longest price label.
///
/// [history] is the full list of purchased items with purchase data.
/// [graphFontSize] is the font size used for the price labels.
/// [extraLetters] pads the label width to account for extra letters.
double _estimateLabelWidth(
  List<PurchasedItemWithPurchase> history,
  double graphFontSize, {
  int? extraLetters = 0,
}) {
  final longestLabel = history.fold<String>('', (current, item) {
    final label = item.purchasedItem.price.toString();
    return label.length > current.length ? label : current;
  });
  final padding = ' ' * extraLetters!;
  final textStyle = TextStyle(fontSize: graphFontSize);
  final textPainter = TextPainter(
    text: TextSpan(text: longestLabel + padding, style: textStyle),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();
  return textPainter.width;
}
