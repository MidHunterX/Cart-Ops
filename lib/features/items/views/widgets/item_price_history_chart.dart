import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shopping_assist/core/database/database.dart';

class ItemPriceHistoryChart extends StatelessWidget {
  final List<PurchasedItemWithPurchase> history;
  final bool isMinimal;

  const ItemPriceHistoryChart({super.key, required this.history, this.isMinimal = false});

  @override
  Widget build(BuildContext context) {
    final validHistory = history.where((h) => h.purchasedItem.price != null).toList();
    if (validHistory.length < 2) return const SizedBox.shrink();

    final chronological = validHistory.reversed.toList();

    final spots = chronological.asMap().entries.map((entry) {
      final index = entry.key.toDouble(); // Use index for X to ensure even spacing
      final h = entry.value;
      final price = h.purchasedItem.price! - h.purchasedItem.discount;
      return FlSpot(index, price);
    }).toList();

    final rawMinX = spots.first.x;
    final rawMaxX = spots.last.x;
    final rawMinY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final rawMaxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    final minX = rawMinX;
    final maxX = rawMaxX;

    double minY = rawMinY;
    double maxY = rawMaxY;
    if (rawMinY == rawMaxY) {
      minY = rawMinY * 0.9;
      maxY = rawMaxY * 1.1;
      if (rawMinY == 0) maxY = 1.0;
    } else {
      // Top padding so the labels don't clip at top
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
                    '\$${touchedSpot.y.toStringAsFixed(2)}',
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
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          lineBarsData: [lineBarData],
          // This keeps the price labels visible at all times
          showingTooltipIndicators: spots.map((spot) {
            return ShowingTooltipIndicators([LineBarSpot(lineBarData, 0, spot)]);
          }).toList(),
        ),
      ),
    );
  }
}
