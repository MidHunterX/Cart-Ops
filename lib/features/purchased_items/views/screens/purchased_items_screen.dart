import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/features/purchased_items/views/widgets/add_purchased_item_sheet.dart';
import 'package:shopping_assist/core/widgets/empty_state.dart';
import 'package:shopping_assist/core/widgets/dextrous_fab.dart';
import 'package:shopping_assist/features/purchased_items/repositories/purchased_items_repository.dart';
import 'package:shopping_assist/features/purchases/repositories/purchases_repository.dart';
import 'package:shopping_assist/features/purchased_items/views/widgets/purchased_item_tile.dart';
import 'package:shopping_assist/features/purchased_items/views/widgets/purchase_summary_card.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import 'package:shopping_assist/features/settings/data/settings_data.dart';

class PurchasedItemsScreen extends StatefulWidget {
  final Purchase purchase;
  final Group? group;

  const PurchasedItemsScreen({super.key, required this.purchase, required this.group});

  @override
  State<PurchasedItemsScreen> createState() => _PurchasedItemsScreenState();
}

class _PurchasedItemsScreenState extends State<PurchasedItemsScreen> {
  final _listKey = GlobalKey<SliverAnimatedListState>();

  List<PurchasedItemWithDetails> _purchasedItems = [];
  StreamSubscription? _itemsSubscription;
  StreamSubscription? _purchaseSubscription;

  late Purchase _currentPurchase;

  bool _isLoading = true;
  bool _isListEmpty = false;

  @override
  void initState() {
    super.initState();
    _currentPurchase = widget.purchase;

    final itemsRepo = context.read<PurchasedItemsRepository>();
    final purchasesRepo = context.read<PurchasesRepository>();

    _purchaseSubscription = purchasesRepo.watchPurchaseById(widget.purchase.id).listen((purchase) {
      if (!mounted) return;
      setState(() {
        _currentPurchase = purchase;
      });
    });

    _itemsSubscription = itemsRepo.watchPurchasedItems(widget.purchase.id).listen((newItems) {
      if (!mounted) return;

      if (_isLoading) {
        setState(() {
          _purchasedItems = List.from(newItems);
          _isListEmpty = _purchasedItems.isEmpty;
          _isLoading = false;
        });
      } else {
        _updateItems(newItems);
      }
    });
  }

  @override
  void dispose() {
    _itemsSubscription?.cancel();
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  void _updateItems(List<PurchasedItemWithDetails> newItems) {
    final currentState = _listKey.currentState;
    if (currentState == null) {
      setState(() {
        _purchasedItems = List.from(newItems);
        _isListEmpty = _purchasedItems.isEmpty;
      });
      return;
    }

    bool hasChanges = false;
    bool hasUpdates = false;

    // Handle removals backwards to avoid index shifting issues
    for (int i = _purchasedItems.length - 1; i >= 0; i--) {
      if (!newItems.any((item) => item.purchasedItem.id == _purchasedItems[i].purchasedItem.id)) {
        final removed = _purchasedItems.removeAt(i);
        hasChanges = true;
        currentState.removeItem(
          i,
          (context, animation) => _buildItemTile(removed, i, _purchasedItems.length, animation),
        );
      }
    }

    // Handle additions and updates
    for (int i = 0; i < newItems.length; i++) {
      if (i >= _purchasedItems.length ||
          _purchasedItems[i].purchasedItem.id != newItems[i].purchasedItem.id) {
        _purchasedItems.insert(i, newItems[i]);
        hasChanges = true;
        currentState.insertItem(i);
      } else {
        // Update the existing item data silently (so total price / counts update gracefully)
        _purchasedItems[i] = newItems[i];
        hasUpdates = true;
      }
    }

    if (hasChanges || hasUpdates) {
      if (_purchasedItems.isEmpty && hasChanges) {
        // Wait for the shrinking animation to complete before popping in the EmptyState
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _purchasedItems.isEmpty) {
            setState(() => _isListEmpty = true);
          }
        });
      } else {
        setState(() => _isListEmpty = _purchasedItems.isEmpty);
      }
    }
  }

  void _showBudgetDialog(BuildContext context) {
    final controller = TextEditingController(
      text: _currentPurchase.budget != null ? _currentPurchase.budget.toString() : '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Budget'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Budget Amount',
            hintText: 'Enter 0 or leave empty to clear',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final budget = double.tryParse(controller.text);
              context.read<PurchasesRepository>().updatePurchaseBudget(
                _currentPurchase.id,
                budget == 0 ? null : budget,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(
    PurchasedItemWithDetails details,
    int index,
    int totalItems,
    Animation<double> animation,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: PurchasedItemTile(details: details, index: index, totalItems: totalItems),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();

    final totalItems = _purchasedItems.length;
    final totalPrice = _purchasedItems.fold<double>(
      0.0,
      (sum, details) =>
          sum +
          (((details.purchasedItem.price ?? 0.0) - details.purchasedItem.discount) *
              (details.purchasedItem.quantity ?? 0.0)),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false, // perf: nothing to resize here on keyboard
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentPurchase.name),
            Text(
              _currentPurchase.purchaseDate.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        backgroundColor: colorScheme.primaryContainer,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'budget') {
                _showBudgetDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'budget', child: Text('Set Budget')),
            ],
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: PurchaseSummaryCard(
                      itemCount: totalItems,
                      total: totalPrice,
                      budget: _currentPurchase.budget,
                    ),
                  ),
                  if (_isListEmpty)
                    const SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.shopping_cart_outlined,
                        title: 'Your Cart is Ready',
                        message: 'Add items to your purchase to see the running total.',
                      ),
                    ),
                  SliverAnimatedList(
                    key: _listKey,
                    initialItemCount: _purchasedItems.length,
                    itemBuilder: (context, index, animation) {
                      return _buildItemTile(_purchasedItems[index], index, totalItems, animation);
                    },
                  ),
                ],
              ),
      ),
      floatingActionButton: DextrousFloatingActionButton(
        isCenter: settings.dominantHand == DominantHand.center,
        icon: Icons.add,
        label: 'Add Item',
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true, // Must resize on graph UI
          useSafeArea: false, // Must be behind keyboard
          builder: (context) =>
              AddPurchasedItemSheet(purchase: _currentPurchase, group: widget.group),
        ),
      ),
      floatingActionButtonLocation: settings.dominantHand == DominantHand.right
          ? FloatingActionButtonLocation.endFloat
          : settings.dominantHand == DominantHand.left
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.centerFloat,
    );
  }
}
