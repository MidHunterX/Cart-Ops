import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/widgets/delete_confirmation_dialog.dart';
import 'package:shopping_assist/core/widgets/empty_state.dart';
import 'package:shopping_assist/features/purchased_items/views/screens/purchased_items_screen.dart';
import 'package:shopping_assist/features/purchases/repositories/purchases_repository.dart';
import 'package:shopping_assist/features/purchases/views/widgets/edit_purchase_dialog.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';

abstract class PurchaseListItem {
  String get id;
}

class MonthHeaderItem extends PurchaseListItem {
  final DateTime month;
  double total;
  MonthHeaderItem(this.month, this.total);
  @override
  String get id => 'header_${month.year}_${month.month}';
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MonthHeaderItem && other.id == id && other.total == total;
  @override
  int get hashCode => id.hashCode ^ total.hashCode;
}

class PurchaseItem extends PurchaseListItem {
  final Purchase purchase;
  PurchaseItem(this.purchase);
  @override
  String get id => 'purchase_${purchase.id}';
}

class PurchasesList extends StatefulWidget {
  final Stream<List<Purchase>> stream;
  final Group? group;
  const PurchasesList({super.key, required this.stream, this.group});
  @override
  State<PurchasesList> createState() => _PurchasesListState();
}

class _PurchasesListState extends State<PurchasesList> {
  final _listKey = GlobalKey<SliverAnimatedListState>();

  List<PurchaseListItem> _items = [];
  StreamSubscription? _purchasesSub;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _purchasesSub = widget.stream.listen((newPurchases) {
      if (!mounted) return;
      final newItems = _generateItems(newPurchases);
      if (_isLoading) {
        setState(() {
          _items = newItems;
          _isLoading = false;
        });
      } else {
        _updateItems(newItems);
      }
    });
  }

  @override
  void dispose() {
    _purchasesSub?.cancel();
    super.dispose();
  }

  List<PurchaseListItem> _generateItems(List<Purchase> purchases) {
    final items = <PurchaseListItem>[];
    if (purchases.isEmpty) return items;

    // First, calculate totals per month
    final totals = <DateTime, double>{};
    for (final p in purchases) {
      final month = DateTime(p.purchaseDate.year, p.purchaseDate.month);
      totals[month] = (totals[month] ?? 0.0) + (p.totalPrice ?? 0.0);
    }

    // Second, build the list by grouping
    DateTime? currentMonth;
    for (final p in purchases) {
      final month = DateTime(p.purchaseDate.year, p.purchaseDate.month);
      if (currentMonth != month) {
        currentMonth = month;
        items.add(MonthHeaderItem(month, totals[month]!));
      }
      items.add(PurchaseItem(p));
    }
    return items;
  }

  void _updateItems(List<PurchaseListItem> newItems) {
    final currentState = _listKey.currentState;
    if (currentState == null) {
      setState(() => _items = newItems);
      return;
    }

    final currentMap = {for (var item in _items) item.id: item};
    final newMap = {for (var item in newItems) item.id: item};

    final removedIds = currentMap.keys.where((id) => !newMap.containsKey(id)).toList();
    final addedIds = newMap.keys.where((id) => !currentMap.containsKey(id)).toSet();

    // Process removals (bottom to top)
    for (int i = _items.length - 1; i >= 0; i--) {
      final item = _items[i];
      if (removedIds.contains(item.id)) {
        final removed = _items.removeAt(i);
        currentState.removeItem(
          i,
          (context, animation) => _buildItem(removed, animation, showDivider: false),
          duration: const Duration(milliseconds: 200),
        );
      }
    }

    // Process additions
    for (int i = 0; i < newItems.length; i++) {
      final item = newItems[i];
      if (addedIds.contains(item.id)) {
        _items.insert(i, item);
        currentState.insertItem(i, duration: const Duration(milliseconds: 200));
      }
    }

    // SYNC DATA AND REBUILD
    // Content of existing items (like total price) might have changed.
    setState(() {
      _items = newItems;
    });
  }

  Widget _buildItem(
    PurchaseListItem item,
    Animation<double> animation, {
    bool showDivider = false,
  }) {
    if (item is MonthHeaderItem) {
      return _MonthHeaderTile(header: item, animation: animation);
    } else if (item is PurchaseItem) {
      return _PurchaseTile(
        purchase: item.purchase,
        animation: animation,
        showDivider: showDivider,
        group: widget.group,
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (_items.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          key: ValueKey('empty_purchases'),
          child: EmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'No Purchases Yet',
            message: 'Start a new shopping event by adding a purchase.',
          ),
        ),
      );
    } else {
      return SliverPadding(
        padding: const EdgeInsets.only(bottom: 80), // Space for FAB
        sliver: SliverAnimatedList(
          key: _listKey,
          initialItemCount: _items.length,
          itemBuilder: (context, index, animation) {
            final item = _items[index];
            final isLast = index == _items.length - 1;
            final isNextHeader = !isLast && _items[index + 1] is MonthHeaderItem;
            return _buildItem(item, animation, showDivider: !(isLast || isNextHeader));
          },
        ),
      );
    }
  }
}

class _MonthHeaderTile extends StatelessWidget {
  final MonthHeaderItem header;
  final Animation<double> animation;

  const _MonthHeaderTile({required this.header, required this.animation});

  String _formatMonth(DateTime date) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;

    final now = DateTime.now();
    final isCurrentMonth = header.month.year == now.year && header.month.month == now.month;

    final monthName = isCurrentMonth ? "This month" : _formatMonth(header.month);
    final colorScheme = Theme.of(context).colorScheme;

    return SizeTransition(
      sizeFactor: animation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: colorScheme.surfaceContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              monthName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$currency${header.total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.secondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseTile extends StatefulWidget {
  final Purchase purchase;
  final Animation<double> animation;
  final bool showDivider;
  final Group? group;

  const _PurchaseTile({
    required this.purchase,
    required this.animation,
    required this.showDivider,
    this.group,
  });

  @override
  State<_PurchaseTile> createState() => _PurchaseTileState();
}

class _PurchaseTileState extends State<_PurchaseTile> {
  bool _isMenuOpen = false;

  void _confirmDelete(BuildContext context, Purchase purchase) {
    DeleteConfirmationDialog.show(
      context,
      title: 'Delete Purchase Event?',
      message: 'Are you sure you want to delete "${purchase.name}"?',
      onDelete: () {
        context.read<PurchasesRepository>().deletePurchase(purchase.id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final purchase = widget.purchase;
    final tileBgColor = _isMenuOpen ? colorScheme.surfaceContainerHighest : null;
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;

    return SizeTransition(
      sizeFactor: widget.animation,
      child: Column(
        children: [
          ListTile(
            tileColor: tileBgColor,
            contentPadding: const EdgeInsets.only(left: 16),
            leading: const Icon(Icons.shopping_cart_outlined),
            title: Text(purchase.name),
            subtitle: Text(
              '${purchase.purchaseDate.day}/${purchase.purchaseDate.month}/${purchase.purchaseDate.year} at ${TimeOfDay.fromDateTime(purchase.purchaseDate).format(context)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$currency${purchase.totalPrice?.toStringAsFixed(2) ?? '0.00'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                PopupMenuButton<String>(
                  onOpened: () => setState(() => _isMenuOpen = true),
                  onCanceled: () => setState(() => _isMenuOpen = false),
                  onSelected: (value) {
                    setState(() => _isMenuOpen = false);
                    if (value == 'edit') {
                      _showEditDialog(context, purchase);
                    } else if (value == 'delete') {
                      _confirmDelete(context, purchase);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit')],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: colorScheme.error),
                          const SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: colorScheme.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onLongPress: () => _showEditDialog(context, purchase),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PurchasedItemsScreen(purchase: purchase, group: widget.group),
              ),
            ),
          ),
          if (widget.showDivider) const Divider(height: 1),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Purchase purchase) {
    showDialog(
      context: context,
      builder: (_) => EditPurchaseDialog(purchase: purchase),
    );
  }
}
