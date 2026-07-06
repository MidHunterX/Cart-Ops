import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/widgets/delete_confirmation_dialog.dart';
import 'package:shopping_assist/core/widgets/empty_state.dart';
import 'package:shopping_assist/features/purchased_items/views/screens/purchased_items_screen.dart';
import 'package:shopping_assist/features/purchases/repositories/purchases_repository.dart';
import 'package:shopping_assist/features/purchases/views/widgets/edit_purchase_dialog.dart';
import 'package:shopping_assist/features/items/views/screens/items_screen.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import 'package:shopping_assist/features/settings/data/settings_data.dart';

class PurchasesScreen extends StatefulWidget {
  final Group group;

  const PurchasesScreen({super.key, required this.group});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final _listKey = GlobalKey<AnimatedListState>();

  List<Purchase> _purchases = [];
  StreamSubscription? _purchasesSub;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final repo = context.read<PurchasesRepository>();

    _purchasesSub = repo.watchPurchasesInGroup(widget.group.id).listen((newPurchases) {
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

    bool hasChanges = false;
    // Handle removals backwards to avoid index shifting issues
    for (int i = _purchases.length - 1; i >= 0; i--) {
      if (!newPurchases.any((p) => p.id == _purchases[i].id)) {
        final removed = _purchases.removeAt(i);
        hasChanges = true;
        currentState.removeItem(
          i,
          (context, animation) =>
              _buildPurchaseTile(context, removed, Theme.of(context).colorScheme, animation, false),
        );
      }
    }
    // Handle additions
    for (int i = 0; i < newPurchases.length; i++) {
      if (i >= _purchases.length || _purchases[i].id != newPurchases[i].id) {
        _purchases.insert(i, newPurchases[i]);
        hasChanges = true;
        currentState.insertItem(i);
      }
    }

    // Delay showing EmptyState until the removal animation finishes
    if (hasChanges && _purchases.isEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _purchases.isEmpty) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final repo = context.read<PurchasesRepository>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.group.name} Purchases'),
        backgroundColor: colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.inventory_2_outlined),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ItemsScreen(group: widget.group)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final purchase = await repo.createPurchase(widget.group.id);
          if (context.mounted) {
            await Future.delayed(const Duration(milliseconds: 300));
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PurchasedItemsScreen(purchase: purchase, group: widget.group),
                ),
              );
            }
          }
        },
        icon: const Icon(Icons.shopping_cart),
        label: const Text('Add Purchase'),
      ),
      floatingActionButtonLocation: settings.dominantHand == DominantHand.right
          ? FloatingActionButtonLocation.endFloat
          : settings.dominantHand == DominantHand.left
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.centerFloat,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _purchases.isEmpty
            ? const EmptyState(
                key: ValueKey('empty_purchases'),
                icon: Icons.shopping_bag_outlined,
                title: 'No Purchases Yet',
                message: 'Start a new shopping event by adding a purchase.',
              )
            : AnimatedList(
                key: _listKey,
                initialItemCount: _purchases.length,
                itemBuilder: (context, index, animation) {
                  return _buildPurchaseTile(
                    context,
                    _purchases[index],
                    colorScheme,
                    animation,
                    index < _purchases.length - 1,
                  );
                },
              ),
      ),
    );
  }

  Widget _buildPurchaseTile(
    BuildContext context,
    Purchase purchase,
    ColorScheme colorScheme,
    Animation<double> animation,
    bool showDivider,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(purchase.name),
            subtitle: Text(
              '${purchase.purchaseDate.day}/${purchase.purchaseDate.month}/${purchase.purchaseDate.year} at ${TimeOfDay.fromDateTime(purchase.purchaseDate).format(context)}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  showDialog(
                    context: context,
                    builder: (_) => EditPurchaseDialog(purchase: purchase),
                  );
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PurchasedItemsScreen(purchase: purchase, group: widget.group),
              ),
            ),
          ),
          if (showDivider) const Divider(height: 1),
        ],
      ),
    );
  }

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
}
