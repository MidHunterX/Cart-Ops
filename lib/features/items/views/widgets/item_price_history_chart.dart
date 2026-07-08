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
    final firstDate = chronological.first.purchase.purchaseDate;

    final spots = chronological.map((h) {
      final days = h.purchase.purchaseDate.difference(firstDate).inDays.toDouble();
      final price = h.purchasedItem.price! - h.purchasedItem.discount;
      return FlSpot(days, price);
    }).toList();

    final rawMinX = spots.first.x;
    final rawMaxX = spots.last.x;
    final rawMinY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final rawMaxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    // Safeguards against crashes when drawing flat lines
    final minX = rawMinX;
    final maxX = rawMinX == rawMaxX ? rawMinX + 1 : rawMaxX;

    double minY = rawMinY;
    double maxY = rawMaxY;
    if (rawMinY == rawMaxY) {
      minY = rawMinY * 0.9;
      maxY = rawMaxY * 1.1;
      if (rawMinY == 0) maxY = 1.0;
    } else {
      // Top padding (0.15 instead of 0.1) so the labels don't clip at top
      final padding = (rawMaxY - rawMinY) * 0.15;
      minY = rawMinY - padding;
      maxY = rawMaxY + padding;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final lineBarData = LineChartBarData(
      spots: spots,
      isCurved: true,
      isStepLineChart: !isMinimal,
      curveSmoothness: 0,
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
      height: isMinimal ? 80 : 220,
      width: double.infinity,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: isMinimal ? false : true),
          titlesData: FlTitlesData(
            show: !isMinimal,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                interval: 2, // x-axis interval
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  // STRICTLY check if a data point exists at this exact day.
                  if (!spots.any((spot) => spot.x == value)) return const SizedBox.shrink();
                  final date = firstDate.add(Duration(days: value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('${date.month}/${date.day}', style: textTheme.bodySmall),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: !isMinimal),

          // Configure tooltips to act as plain persistent labels
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
                    touchedSpot.y.toStringAsFixed(1),
                    textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold) ??
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

          // Map all data spots to persistently display tooltips right over them
          showingTooltipIndicators: spots.map((spot) {
            return ShowingTooltipIndicators([LineBarSpot(lineBarData, 0, spot)]);
          }).toList(),
        ),
      ),
    );
  }
}
