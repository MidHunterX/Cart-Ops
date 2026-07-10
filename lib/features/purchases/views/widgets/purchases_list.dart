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

class PurchasesList extends StatefulWidget {
  final Stream<List<Purchase>> stream;
  final Group? group;

  const PurchasesList({super.key, required this.stream, this.group});

  @override
  State<PurchasesList> createState() => _PurchasesListState();
}

class _PurchasesListState extends State<PurchasesList> {
  final _listKey = GlobalKey<SliverAnimatedListState>();

  List<Purchase> _purchases = [];
  StreamSubscription? _purchasesSub;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _purchasesSub = widget.stream.listen((newPurchases) {
      if (!mounted) return;
      if (_isLoading) {
        setState(() {
          _purchases = List.from(newPurchases);
          _isLoading = false;
        });
      } else {
        _updatePurchases(newPurchases);
      }
    });
  }

  @override
  void dispose() {
    _purchasesSub?.cancel();
    super.dispose();
  }

  void _updatePurchases(List<Purchase> newPurchases) {
    final currentState = _listKey.currentState;
    if (currentState == null) {
      setState(() => _purchases = List.from(newPurchases));
      return;
    }

    final currentMap = {for (var p in _purchases) p.id: p};
    final newMap = {for (var p in newPurchases) p.id: p};

    final removedIds = currentMap.keys.where((id) => !newMap.containsKey(id)).toList();
    final addedIds = newMap.keys.where((id) => !currentMap.containsKey(id)).toSet();

    // Process removals (bottom to top)
    for (int i = _purchases.length - 1; i >= 0; i--) {
      if (removedIds.contains(_purchases[i].id)) {
        final removed = _purchases.removeAt(i);
        currentState.removeItem(
          i,
          (context, animation) => _PurchaseTile(
            purchase: removed,
            animation: animation,
            showDivider: false,
            group: widget.group,
          ),
          duration: const Duration(milliseconds: 200),
        );
      }
    }

    // Process additions
    for (int i = 0; i < newPurchases.length; i++) {
      final item = newPurchases[i];
      if (addedIds.contains(item.id)) {
        _purchases.insert(i, item);
        currentState.insertItem(i, duration: const Duration(milliseconds: 200));
      }
    }

    // SYNC DATA AND REBUILD
    // Even if no items were added/removed, the content (totalPrice) of
    // existing items might have changed.
    setState(() {
      _purchases = List.from(newPurchases);
    });
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
    } else if (_purchases.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          key: ValueKey('empty_purchases'),
          padding: EdgeInsets.only(top: 32.0),
          child: EmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'No Purchases Yet',
            message: 'Start a new shopping event by adding a purchase.',
          ),
        ),
      );
    } else {
      return SliverAnimatedList(
        key: _listKey,
        initialItemCount: _purchases.length,
        itemBuilder: (context, index, animation) {
          return _PurchaseTile(
            purchase: _purchases[index],
            animation: animation,
            showDivider: index < _purchases.length - 1,
            group: widget.group,
          );
        },
      );
    }
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
    final tileBgColor = _isMenuOpen ? colorScheme.primary.withValues(alpha: 0.2) : null;
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;

    return SizeTransition(
      sizeFactor: widget.animation,
      child: Column(
        children: [
          ListTile(
            tileColor: tileBgColor,
            contentPadding: const EdgeInsets.only(left: 16, right: 4),
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
