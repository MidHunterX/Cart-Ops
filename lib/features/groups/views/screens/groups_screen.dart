import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/widgets/delete_confirmation_dialog.dart';
import 'package:shopping_assist/core/widgets/empty_state.dart';
import 'package:shopping_assist/core/widgets/dextrous_fab.dart';
import 'package:shopping_assist/features/groups/repositories/groups_repository.dart';
import 'package:shopping_assist/features/groups/views/widgets/add_group_dialog.dart';
import 'package:shopping_assist/features/purchased_items/views/screens/purchased_items_screen.dart';
import 'package:shopping_assist/features/purchases/repositories/purchases_repository.dart';
import 'package:shopping_assist/features/purchases/views/screens/purchases_screen.dart';
import 'package:shopping_assist/features/purchases/views/widgets/edit_purchase_dialog.dart';
import 'package:shopping_assist/features/items/views/screens/items_screen.dart';
import 'package:shopping_assist/features/settings/views/settings_screen.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import 'package:shopping_assist/features/settings/data/settings_data.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _listKey = GlobalKey<AnimatedListState>();

  List<Group> _groups = [];
  List<Purchase> _purchases = [];

  StreamSubscription? _groupsSub;
  StreamSubscription? _purchasesSub;

  bool _isLoadingGroups = true;
  bool _isLoadingPurchases = true;

  @override
  void initState() {
    super.initState();
    final groupsRepo = context.read<GroupsRepository>();
    final purchasesRepo = context.read<PurchasesRepository>();

    _groupsSub = groupsRepo.watchGroups().listen((newGroups) {
      if (!mounted) return;
      setState(() {
        _groups = newGroups;
        _isLoadingGroups = false;
      });
    });

    _purchasesSub = purchasesRepo.watchGeneralPurchases().listen((newPurchases) {
      if (!mounted) return;
      if (_isLoadingPurchases) {
        setState(() {
          _purchases = List.from(newPurchases);
          _isLoadingPurchases = false;
        });
      } else {
        _updatePurchases(newPurchases);
      }
    });
  }

  @override
  void dispose() {
    _groupsSub?.cancel();
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
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart Ops'),
        backgroundColor: colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.inventory_2_outlined),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ItemsScreen(group: null)),
            ),
          ),
          IconButton(
            icon: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.settings)),
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      floatingActionButton: DextrousFloatingActionButton(
        isCenter: settings.dominantHand == DominantHand.center,
        icon: Icons.shopping_cart,
        label: 'Add Purchase',
        onPressed: () async {
          final purchase = await context.read<PurchasesRepository>().createPurchase(null);
          if (context.mounted) {
            await Future.delayed(const Duration(milliseconds: 300));
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PurchasedItemsScreen(purchase: purchase, group: null),
                ),
              );
            }
          }
        },
      ),
      floatingActionButtonLocation: settings.dominantHand == DominantHand.right
          ? FloatingActionButtonLocation.endFloat
          : settings.dominantHand == DominantHand.left
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.centerFloat,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Text('My Groups', style: Theme.of(context).textTheme.titleLarge),
          ),
          _isLoadingGroups
              ? const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()))
              : SizedBox(
                  height: 150,
                  child: GridView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      mainAxisSpacing: 16,
                      crossAxisCount: 1,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _groups.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _groups.length) {
                        return _buildAddGroupTile(context, colorScheme);
                      }
                      return _buildGroupTile(context, _groups[index], colorScheme);
                    },
                  ),
                ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
            child: Text('General Purchases', style: Theme.of(context).textTheme.titleLarge),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isLoadingPurchases
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _purchases.isEmpty
                ? const Padding(
                    key: ValueKey('empty_purchases'),
                    padding: EdgeInsets.only(top: 32.0),
                    child: EmptyState(
                      icon: Icons.shopping_bag_outlined,
                      title: 'No Purchases Yet',
                      message: 'Start a new shopping event by adding a purchase.',
                    ),
                  )
                : AnimatedList(
                    key: _listKey,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
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
        ],
      ),
    );
  }

  Widget _buildGroupTile(BuildContext context, Group group, ColorScheme colorScheme) {
    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => PurchasesScreen(group: group))),
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront, size: 36, color: colorScheme.primary),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      group.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Icon(Icons.close, size: 18, color: colorScheme.onSurfaceVariant),
                onPressed: () => _confirmDeleteGroup(context, group),
              ),
            ),
          ],
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
                  _confirmDeletePurchase(context, purchase);
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
                builder: (_) => PurchasedItemsScreen(purchase: purchase, group: null),
              ),
            ),
          ),
          if (showDivider) const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildAddGroupTile(BuildContext context, ColorScheme colorScheme) {
    return InkWell(
      onTap: () => showDialog(context: context, builder: (_) => const AddGroupDialog()),
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.surfaceContainerHighest, width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 36, color: colorScheme.secondary),
              const SizedBox(height: 12),
              Text('Add Group', style: TextStyle(color: colorScheme.secondary)),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context, Group group) {
    DeleteConfirmationDialog.show(
      context,
      title: 'Delete Group?',
      message:
          'Are you sure you want to delete "${group.name}"? This will also remove all its purchase history.',
      onDelete: () => context.read<GroupsRepository>().deleteGroup(group.id),
    );
  }

  void _confirmDeletePurchase(BuildContext context, Purchase purchase) {
    DeleteConfirmationDialog.show(
      context,
      title: 'Delete Purchase Event?',
      message: 'Are you sure you want to delete "${purchase.name}"?',
      onDelete: () => context.read<PurchasesRepository>().deletePurchase(purchase.id),
    );
  }
}
