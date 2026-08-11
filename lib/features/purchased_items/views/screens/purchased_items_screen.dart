import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/utils/datetime_formatter.dart';
import 'package:shopping_assist/core/utils/number_formatter.dart';
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
  int? _selectedItemId;

  List<PurchasedItemWithDetails> _purchasedItems = [];
  StreamSubscription? _itemsSubscription;
  StreamSubscription? _purchaseSubscription;

  late Purchase _currentPurchase;

  bool _isLoading = true;
  bool _isListEmpty = false;
  bool _showAsBudgetPercentage = false;

  // Search feature
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
        if (_currentPurchase.budget == null || _currentPurchase.budget! <= 0) {
          _showAsBudgetPercentage = false;
        }
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
    _searchController.dispose();
    _itemsSubscription?.cancel();
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  List<PurchasedItemWithDetails> get _filteredItems {
    if (_searchQuery.trim().isEmpty) return _purchasedItems;
    final query = _searchQuery.trim().toLowerCase();
    return _purchasedItems.where((item) {
      final name = item.item.name.toLowerCase();
      final pName = (item.purchasedItem.name ?? '').toLowerCase();
      return name.contains(query) || pName.contains(query);
    }).toList();
  }

  void _updateItems(List<PurchasedItemWithDetails> newItems) {
    final currentState = _listKey.currentState;
    if (currentState == null || _isSearching) {
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
              if (budget == null || budget <= 0) {
                setState(() => _showAsBudgetPercentage = false);
              }
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
    int totalItemsListLength,
    Animation<double> animation,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: PurchasedItemTile(
        details: details,
        index: index,
        totalItems: totalItemsListLength,
        isSelected: _selectedItemId == details.purchasedItem.id,
        isChecklistMode: _currentPurchase.isChecklistMode,
        showAsBudgetPercentage: _showAsBudgetPercentage,
        budget: _currentPurchase.budget,
        onToggleCheck: (val) {
          context.read<PurchasedItemsRepository>().toggleItemCheck(
            details.purchasedItem.id,
            val ?? false,
          );
        },
        onMenuOpened: () => setState(() => _selectedItemId = details.purchasedItem.id),
        onMenuClosed: () => setState(() => _selectedItemId = null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayItemsList = _filteredItems;
    final totalItemsListLength = _purchasedItems.length;
    int displayTotalItems = totalItemsListLength;
    double displayTotalPrice = _currentPurchase.totalPrice ?? 0.0;

    final currencySymbol = context.currencySymbol;
    final currencyLocale = context.currencyLocale;
    final hasBudget = _currentPurchase.budget != null && _currentPurchase.budget! > 0;

    bool? allCheckedState;
    if (_currentPurchase.isChecklistMode && totalItemsListLength > 0) {
      final checkedCount = _purchasedItems.where((item) => item.purchasedItem.isChecked).length;
      if (checkedCount == 0) {
        allCheckedState = false;
      } else if (checkedCount == totalItemsListLength) {
        allCheckedState = true;
      } else {
        allCheckedState = null; // Indeterminate
      }

      displayTotalItems = checkedCount;
      displayTotalPrice = _purchasedItems.where((item) => item.purchasedItem.isChecked).fold(0.0, (
        sum,
        item,
      ) {
        final price = item.purchasedItem.price ?? 0.0;
        final qty = item.purchasedItem.quantity ?? 0.0;
        final discountPercent = item.purchasedItem.discount;
        final discountAmount = price * (discountPercent / 100);
        return sum + ((price - discountAmount) * qty);
      });
    }

    return Scaffold(
      resizeToAvoidBottomInset: false, // perf: nothing to resize here on keyboard
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                style: TextStyle(color: colorScheme.onSurface),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_currentPurchase.name),
                  Text(
                    '${_currentPurchase.purchaseDate.toLongDate} at ${_currentPurchase.purchaseDate.toShortTime}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
        surfaceTintColor: colorScheme.primaryContainer,
        backgroundColor: colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'budget') {
                _showBudgetDialog(context);
              } else if (value == 'toggle_checklist') {
                context.read<PurchasesRepository>().updateChecklistMode(
                  _currentPurchase.id,
                  !_currentPurchase.isChecklistMode,
                );
              } else if (value == 'toggle_budget_percent') {
                setState(() {
                  _showAsBudgetPercentage = !_showAsBudgetPercentage;
                });
              }
            },
            itemBuilder: (context) => [
              // GROUP 1: VIEW OPTIONS
              if (hasBudget)
                PopupMenuItem(
                  value: 'toggle_budget_percent',
                  child: Row(
                    spacing: 8,
                    children: [
                      Icon(
                        _showAsBudgetPercentage
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      Text(_showAsBudgetPercentage ? 'Hide Percentages' : 'Show Percentages'),
                    ],
                  ),
                ),

              // GROUP 2: SETTINGS (MODIFY BEHAVIOR)
              PopupMenuItem(
                value: 'toggle_checklist',
                child: Row(
                  spacing: 8,
                  children: [
                    Icon(
                      _currentPurchase.isChecklistMode
                          ? Icons.checklist_rtl
                          : Icons.checklist_outlined,
                    ),
                    const Text('Checklist Mode'),
                    if (_currentPurchase.isChecklistMode) const Icon(Icons.check_circle, size: 16),
                  ],
                ),
              ),

              // GROUP 3: ACTIONS (OPEN DIALOGS)
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'budget',
                child: ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: Text(hasBudget ? 'Edit Budget' : 'Set Budget'),
                  subtitle: hasBudget
                      ? Text(
                          'Current: ${_currentPurchase.budget?.toCurrencyString(currencySymbol, locale: currencyLocale)}',
                        )
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          PurchaseSummaryCard(
            purchaseId: _currentPurchase.id,
            itemCount: displayTotalItems,
            totalItems: totalItemsListLength,
            isChecklistMode: _currentPurchase.isChecklistMode,
            total: displayTotalPrice,
            budget: _currentPurchase.budget,
            allChecked: allCheckedState,
            onToggleAll: (bool? checkAll) {
              bool isAllChecked = checkAll == null;
              bool isNoneChecked = checkAll == true;
              bool isSomeChecked = checkAll == false;
              bool lessItemsChecked = displayTotalItems < (totalItemsListLength / 2);
              isAllChecked
                  ? checkAll = false
                  : isNoneChecked
                  ? checkAll = true
                  : isSomeChecked
                  ? lessItemsChecked
                        ? checkAll = false
                        : checkAll = true
                  : null;
              context.read<PurchasedItemsRepository>().setAllItemsCheckState(
                _currentPurchase.id,
                checkAll,
              );
            },
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (_isListEmpty || displayItemsList.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: _isSearching ? Icons.search_off_outlined : Icons.shopping_cart_outlined,
                      title: _isSearching ? 'No Matching Items' : 'Your Cart is Ready',
                      message: _isSearching
                          ? 'Try entering a different item name.'
                          : 'Add some items to see the running total.',
                    ),
                  ),
                if (!_isListEmpty && displayItemsList.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 80),
                    sliver: _isSearching
                        ? SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => PurchasedItemTile(
                                details: displayItemsList[index],
                                index: index,
                                totalItems: displayItemsList.length,
                                isSelected:
                                    _selectedItemId == displayItemsList[index].purchasedItem.id,
                                isChecklistMode: _currentPurchase.isChecklistMode,
                                showAsBudgetPercentage: _showAsBudgetPercentage,
                                budget: _currentPurchase.budget,
                                onToggleCheck: (val) {
                                  context.read<PurchasedItemsRepository>().toggleItemCheck(
                                    displayItemsList[index].purchasedItem.id,
                                    val ?? false,
                                  );
                                },
                                onMenuOpened: () => setState(
                                  () => _selectedItemId = displayItemsList[index].purchasedItem.id,
                                ),
                                onMenuClosed: () => setState(() => _selectedItemId = null),
                              ),
                              childCount: displayItemsList.length,
                            ),
                          )
                        : SliverAnimatedList(
                            key: _listKey,
                            initialItemCount: _purchasedItems.length,
                            itemBuilder: (context, index, animation) {
                              return _buildItemTile(
                                _purchasedItems[index],
                                index,
                                totalItemsListLength,
                                animation,
                              );
                            },
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: DextrousFloatingActionButton(
        isCenter: context.dominantHand == DominantHand.center,
        icon: Icons.add,
        label: 'Add Item',
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true, // Must resize on graph UI
          useSafeArea: false, // Must be behind keyboard
          enableDrag: false, // Disable dismiss gestures for messy fast typing
          showDragHandle: true, // but, can be dismissed with the handle
          builder: (context) =>
              AddPurchasedItemSheet(purchase: _currentPurchase, group: widget.group),
        ),
      ),
      floatingActionButtonLocation: context.dominantHand == DominantHand.right
          ? FloatingActionButtonLocation.endFloat
          : context.dominantHand == DominantHand.left
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.centerFloat,
    );
  }
}
