import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/widgets/delete_confirmation_dialog.dart';
import 'package:shopping_assist/core/widgets/empty_state.dart';
import 'package:shopping_assist/features/purchased_items/views/screens/purchased_items_screen.dart';
import 'package:shopping_assist/features/purchases/repositories/purchases_repository.dart';
import 'package:shopping_assist/features/purchases/views/widgets/edit_purchase_dialog.dart';

class PurchasesList extends StatefulWidget {
  final Stream<List<Purchase>> stream;
  final Group? group;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const PurchasesList({
    super.key,
    required this.stream,
    this.group,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<PurchasesList> createState() => _PurchasesListState();
}

class _PurchasesListState extends State<PurchasesList> {
  final _listKey = GlobalKey<AnimatedListState>();

  List<Purchase> _purchases = [];
  StreamSubscription? _purchasesSub;
  bool _isLoading = true;

  int? _selectedPurchaseId;

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

    bool hasChanges = false;
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
    for (int i = 0; i < newPurchases.length; i++) {
      if (i >= _purchases.length || _purchases[i].id != newPurchases[i].id) {
        _purchases.insert(i, newPurchases[i]);
        hasChanges = true;
        currentState.insertItem(i);
      }
    }

    if (hasChanges && _purchases.isEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _purchases.isEmpty) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_purchases.isEmpty) {
      content = const Padding(
        key: ValueKey('empty_purchases'),
        padding: EdgeInsets.only(top: 32.0),
        child: EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'No Purchases Yet',
          message: 'Start a new shopping event by adding a purchase.',
        ),
      );
    } else {
      content = AnimatedList(
        key: _listKey,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        padding: EdgeInsets.zero,
        initialItemCount: _purchases.length,
        itemBuilder: (context, index, animation) {
          return _buildPurchaseTile(
            context,
            _purchases[index],
            Theme.of(context).colorScheme,
            animation,
            index < _purchases.length - 1,
          );
        },
      );
    }

    return AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: content);
  }

  Widget _buildPurchaseTile(
    BuildContext context,
    Purchase purchase,
    ColorScheme colorScheme,
    Animation<double> animation,
    bool showDivider,
  ) {
    final isMenuOpen = _selectedPurchaseId == purchase.id;
    final tileBgColor = isMenuOpen ? colorScheme.primary.withValues(alpha: 0.2) : null;
    return SizeTransition(
      sizeFactor: animation,
      child: Column(
        children: [
          ListTile(
            tileColor: tileBgColor,
            contentPadding: const EdgeInsets.only(left: 16, right: 4),
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(purchase.name),
            subtitle: Text(
              '${purchase.purchaseDate.day}/${purchase.purchaseDate.month}/${purchase.purchaseDate.year} at ${TimeOfDay.fromDateTime(purchase.purchaseDate).format(context)}',
            ),
            trailing: PopupMenuButton<String>(
              onOpened: () => setState(() => _selectedPurchaseId = purchase.id),
              onCanceled: () => setState(() => _selectedPurchaseId = null),
              onSelected: (value) {
                setState(() => _selectedPurchaseId = null);
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
