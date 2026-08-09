import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/utils/datetime_formatter.dart';
import 'package:shopping_assist/core/utils/number_formatter.dart';
import 'package:shopping_assist/core/widgets/item_image_view.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';
import 'package:shopping_assist/features/items/views/widgets/item_price_history_chart.dart';

/// Aggregated stats derived from an item's purchase history, computed once
/// per build so every widget below can just read fields instead of looping.
class _ItemStats {
  final int count;
  final double avgPrice;
  final double minPrice;
  final DateTime minPriceDate;
  final double maxPrice;
  final DateTime maxPriceDate;
  final double totalQuantity;
  final bool isWeight;
  final DateTime lastPurchaseDate;
  final int trend; // -1 down, 0 flat/unknown, 1 up
  final List<PurchasedItemWithPurchase> chronological; // oldest -> newest
  final List<PurchasedItemWithPurchase> recentFirst; // newest -> oldest

  _ItemStats({
    required this.count,
    required this.avgPrice,
    required this.minPrice,
    required this.minPriceDate,
    required this.maxPrice,
    required this.maxPriceDate,
    required this.totalQuantity,
    required this.isWeight,
    required this.lastPurchaseDate,
    required this.trend,
    required this.chronological,
    required this.recentFirst,
  });

  static double _discounted(PurchasedItem p) => (p.price ?? 0) * (1 - p.discount / 100);

  factory _ItemStats.from(List<PurchasedItemWithPurchase> history) {
    final chronological = [...history]
      ..sort((a, b) => a.purchase.purchaseDate.compareTo(b.purchase.purchaseDate));

    double totalSpent = 0;
    double totalQuantity = 0;
    double minPrice = double.infinity;
    double maxPrice = -double.infinity;
    DateTime minDate = chronological.first.purchase.purchaseDate;
    DateTime maxDate = chronological.first.purchase.purchaseDate;

    for (final h in chronological) {
      final p = h.purchasedItem;
      final discounted = _discounted(p);
      totalSpent += discounted;
      final qty = p.quantity ?? 0;
      final packs = p.packQuantity ?? 1;
      totalQuantity += qty * packs;
      if (discounted < minPrice) {
        minPrice = discounted;
        minDate = h.purchase.purchaseDate;
      }
      if (discounted > maxPrice) {
        maxPrice = discounted;
        maxDate = h.purchase.purchaseDate;
      }
    }

    int trend = 0;
    if (chronological.length >= 2) {
      final last = _discounted(chronological.last.purchasedItem);
      final prev = _discounted(chronological[chronological.length - 2].purchasedItem);
      if (last > prev) {
        trend = 1;
      } else if (last < prev) {
        trend = -1;
      }
    }

    return _ItemStats(
      count: chronological.length,
      avgPrice: totalSpent / chronological.length,
      minPrice: minPrice,
      minPriceDate: minDate,
      maxPrice: maxPrice,
      maxPriceDate: maxDate,
      totalQuantity: totalQuantity,
      isWeight: chronological.first.purchasedItem.isWeight,
      lastPurchaseDate: chronological.last.purchase.purchaseDate,
      trend: trend,
      chronological: chronological,
      recentFirst: chronological.reversed.toList(),
    );
  }
}

class ItemDetailScreen extends StatelessWidget {
  final Item item;
  final String? tag;
  const ItemDetailScreen({super.key, required this.item, this.tag});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ItemsRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Item Details')),
      body: FutureBuilder<List<PurchasedItemWithPurchase>>(
        future: repo.getPurchaseHistoryForItem(item.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final history = snapshot.data ?? [];
          final stats = _ItemStats.from(history);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  item: item,
                  stats: stats,
                  tag: tag ?? 'item_detail_${item.id}',
                  daysAgoText: stats.lastPurchaseDate.toRelativeTime(),
                ),
                const SizedBox(height: 24),

                _StatsGrid(stats: stats),
                const SizedBox(height: 16),

                _PriceRangeCard(stats: stats),
                const SizedBox(height: 24),

                if (stats.count >= 2) ...[
                  Row(
                    children: [
                      Text('Price Trend', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(width: 8),
                      _TrendBadge(trend: stats.trend),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ItemPriceHistoryChart(history: stats.recentFirst),
                  const SizedBox(height: 24),
                ],

                Text(
                  'Purchase History (${stats.count})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stats.recentFirst.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (ctx, index) {
                    final itemWithPurchase = stats.recentFirst[index];
                    final isBest = itemWithPurchase.purchase.purchaseDate == stats.minPriceDate;
                    return _HistoryTile(entry: itemWithPurchase, isBestPrice: isBest);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Item item;
  final _ItemStats stats;
  final String daysAgoText;
  final String? tag;
  const _Header({required this.item, required this.stats, required this.daysAgoText, this.tag});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.imagePath != null) ...[
          Center(
            child: ItemImageView(
              imagePath: item.imagePath,
              height: 200,
              width: double.maxFinite,
              borderRadius: BorderRadius.circular(16),
              heroTag: tag,
              enableTapToView: true,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(item.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.event_repeat, size: 16, color: colorScheme.outline),
            const SizedBox(width: 4),
            Text(
              'Last bought $daysAgoText',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final _ItemStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _StatCard(
          icon: Icons.shopping_cart_outlined,
          label: 'Times Bought',
          value: '${stats.count}',
          color: colorScheme.secondary,
        ),
        _StatCard(
          icon: Icons.trending_flat,
          label: 'Avg Price',
          value: stats.avgPrice.toCurrencyString(
            context.currencySymbol,
            locale: context.currencyLocale,
          ),
          color: colorScheme.tertiary,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.20), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colorScheme.outline),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRangeCard extends StatelessWidget {
  final _ItemStats stats;
  const _PriceRangeCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PriceRangeEntry(
              icon: Icons.arrow_downward,
              iconColor: Colors.green,
              label: 'Lowest',
              price: stats.minPrice,
              dateLabel: stats.minPriceDate.toShortDateWithDay,
            ),
          ),
          Container(width: 1, height: 40, color: colorScheme.outlineVariant),
          Expanded(
            child: _PriceRangeEntry(
              icon: Icons.arrow_upward,
              iconColor: Colors.redAccent,
              label: 'Highest',
              price: stats.maxPrice,
              dateLabel: stats.maxPriceDate.toShortDateWithDay,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRangeEntry extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final double price;
  final String dateLabel;
  const _PriceRangeEntry({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.price,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          price.toCurrencyString(context.currencySymbol, locale: context.currencyLocale),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          dateLabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.outline),
        ),
      ],
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final int trend;
  const _TrendBadge({required this.trend});

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final Color color;
    late final String label;
    switch (trend) {
      case 1:
        icon = Icons.trending_up;
        color = Colors.redAccent;
        label = 'Rising';
        break;
      case -1:
        icon = Icons.trending_down;
        color = Colors.greenAccent;
        label = 'Falling';
        break;
      default:
        icon = Icons.trending_flat;
        color = Theme.of(context).colorScheme.outline;
        label = 'Stable';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final PurchasedItemWithPurchase entry;
  final bool isBestPrice;
  const _HistoryTile({required this.entry, required this.isBestPrice});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final p = entry.purchasedItem;
    final purchase = entry.purchase;

    // CORE PRICING
    final originalUnitPrice = p.price ?? 0;
    final discountPercent = p.discount;
    final discountedUnitPrice = originalUnitPrice * (1 - discountPercent / 100);

    // QUANTITIES
    final perPackQty = p.quantity ?? 1;
    final packCount = p.packQuantity ?? 1;
    final totalQuantity = perPackQty * packCount;

    final bool isWeight = p.isWeight;
    // final bool isPack = p.packQuantity != null;

    // DERIVED VALUES
    final totalCost = ((discountedUnitPrice * totalQuantity) * 100).round() / 100;
    // final originalTotalCost = originalUnitPrice * totalQuantity;
    // final savings = originalTotalCost - totalCost;
    final perOriginalUnitPrice = ((originalUnitPrice * perPackQty) * 100).round() / 100;
    final perDiscountedUnitPrice = ((discountedUnitPrice * perPackQty) * 100).round() / 100;

    // FORMATTING
    final unitString = isWeight ? context.weightUnit : 'pc';
    final perUnitQtyFmt = perPackQty.toQuantityString(unitString);
    final perOriginalUnitPriceFmt = perOriginalUnitPrice.toCurrencyString(
      context.currencySymbol,
      locale: context.currencyLocale,
      preferWhole: true,
    );
    final perDiscountedUnitPriceFmt = perDiscountedUnitPrice.toCurrencyString(
      context.currencySymbol,
      locale: context.currencyLocale,
      preferWhole: true,
    );
    final discountedUnitPriceFmt = discountedUnitPrice.toCurrencyString(
      context.currencySymbol,
      locale: context.currencyLocale,
    );
    final originalUnitPriceFmt = originalUnitPrice.toCurrencyString(
      context.currencySymbol,
      locale: context.currencyLocale,
    );
    final totalCostFmt = totalCost.toCurrencyString(
      context.currencySymbol,
      locale: context.currencyLocale,
      preferWhole: true,
    );

    Widget subtitle;
    if (packCount > 1) {
      subtitle = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$perOriginalUnitPriceFmt ',
                style: textTheme.bodyMedium!.copyWith(
                  color: colorScheme.secondary,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              Text(
                '$perDiscountedUnitPriceFmt / $perUnitQtyFmt',
                style: textTheme.bodyMedium!.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text('${packCount.toQuantityString('')} packs · Total: $totalCostFmt'),
        ],
      );
    } else {
      subtitle = Text('$perUnitQtyFmt · Total: $totalCostFmt');
    }

    return ListTile(
      contentPadding: const EdgeInsets.all(0),
      leading: CircleAvatar(
        backgroundColor: isBestPrice
            ? Colors.green.withValues(alpha: 0.30)
            : colorScheme.secondaryContainer,
        child: Icon(
          isBestPrice ? Icons.star : Icons.history,
          color: isBestPrice ? Colors.green : colorScheme.onSecondaryContainer,
        ),
      ),
      title: Row(
        children: [
          Text(
            purchase.purchaseDate.toIsoDate,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (isBestPrice) ...[
            const SizedBox(width: 6),
            Text(
              'BEST PRICE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ],
      ),
      subtitle: subtitle,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                discountedUnitPriceFmt,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 18,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' /$unitString',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontSize: 12, color: colorScheme.primary),
              ),
            ],
          ),
          if (p.discount > 0)
            Text(
              originalUnitPriceFmt,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.secondary,
                decoration: TextDecoration.lineThrough,
              ),
            ),
        ],
      ),
    );
  }
}
