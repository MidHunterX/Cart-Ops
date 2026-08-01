import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/utils/graph_utils.dart';
import 'package:shopping_assist/core/utils/number_formatter.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';

class ItemPriceHistoryChart extends StatelessWidget {
  final List<PurchasedItemWithPurchase> history;
  final bool isMinimal;

  const ItemPriceHistoryChart({super.key, required this.history, this.isMinimal = false});

  @override
  Widget build(BuildContext context) {
    final currency = context.currencySymbol;

    final validHistory = history.where((h) => h.purchasedItem.price != null).toList();
    if (validHistory.length < 2) return const SizedBox.shrink();

    final chronological = validHistory.reversed.toList();

    // Deduplicate consecutive points with similar final price
    const double epsilon = 0.001;
    final deduped = <PurchasedItemWithPurchase>[];
    if (chronological.length == 2) {
      // Special case for two points
      deduped.addAll(chronological);
    } else {
      for (var i = 0; i < chronological.length; i++) {
        final current = chronological[i];
        final currentPrice = current.purchasedItem.price! - current.purchasedItem.discount;
        if (i == 0) {
          deduped.add(current);
        } else {
          final previous = deduped.last;
          final previousPrice = previous.purchasedItem.price! - previous.purchasedItem.discount;
          if ((currentPrice - previousPrice).abs() > epsilon) {
            deduped.add(current);
          }
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        final maxDataPoints = calculateMaxDataPoints(
          context,
          validHistory,
          maxWidth: availableWidth,
          extraLetters: currency.length + 1, // currency + space
        );

        final displayHistory = deduped.take(maxDataPoints).toList();
        if (displayHistory.length < 2) return const SizedBox.shrink();

        final spots = displayHistory.asMap().entries.map((entry) {
          final index = entry.key.toDouble();
          final h = entry.value;
          final discountPercentage = h.purchasedItem.discount;
          final originalPrice = h.purchasedItem.price!;
          final discountedPrice = originalPrice * (1 - discountPercentage / 100);
          return FlSpot(index, discountedPrice);
        }).toList();

        final rawMinX = spots.first.x;
        final rawMaxX = spots.last.x;
        final rawMinY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
        final rawMaxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

        double minY = rawMinY;
        double maxY = rawMaxY;
        if (rawMinY == rawMaxY) {
          minY = rawMinY * 0.9;
          maxY = rawMaxY * 1.1;
          if (rawMinY == 0) maxY = 1.0;
        } else {
          final padding = (rawMaxY - rawMinY) * 0.2;
          minY = rawMinY - padding;
          maxY = rawMaxY + padding;
        }

        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        final lineBarData = LineChartBarData(
          spots: spots,
          isCurved: true,
          isStepLineChart: !isMinimal,
          curveSmoothness: 0.3,
          preventCurveOverShooting: true,
          color: colorScheme.primary,
          barWidth: isMinimal ? 2 : 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: isMinimal ? 3 : 4,
                color: colorScheme.primary,
                strokeWidth: 0,
              );
            },
          ),
          belowBarData: BarAreaData(show: true, color: colorScheme.primary.withValues(alpha: 0.2)),
        );

        return SizedBox(
          height: isMinimal ? 80 : 200,
          width: double.infinity,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                enabled: true,
                handleBuiltInTouches: false,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => Colors.transparent,
                  tooltipPadding: EdgeInsets.zero,
                  tooltipMargin: 8,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((touchedSpot) {
                      return LineTooltipItem(
                        touchedSpot.y.toCurrencyString(currency),
                        textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ) ??
                            const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      );
                    }).toList();
                  },
                ),
              ),
              minX: rawMinX,
              maxX: rawMaxX,
              minY: minY,
              maxY: maxY,
              lineBarsData: [lineBarData],
              showingTooltipIndicators: spots.map((spot) {
                return ShowingTooltipIndicators([LineBarSpot(lineBarData, 0, spot)]);
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
