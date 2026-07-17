import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/widgets/delete_confirmation_dialog.dart';
import 'package:shopping_assist/core/widgets/dextrous_fab.dart';
import 'package:shopping_assist/features/groups/repositories/groups_repository.dart';
import 'package:shopping_assist/features/groups/views/widgets/add_group_dialog.dart';
import 'package:shopping_assist/features/purchased_items/views/screens/purchased_items_screen.dart';
import 'package:shopping_assist/features/purchases/repositories/purchases_repository.dart';
import 'package:shopping_assist/features/purchases/views/screens/purchases_screen.dart';
import 'package:shopping_assist/features/purchases/views/widgets/purchases_list.dart';
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
  List<Group> _groups = [];
  StreamSubscription? _groupsSub;
  StreamSubscription? _ungroupedPurchasesCountSub;
  bool _isLoadingGroups = true;
  int _ungroupedPurchasesCount = 0;

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

    _ungroupedPurchasesCountSub = purchasesRepo.watchPurchasesCount().listen((count) {
      if (!mounted) return;
      setState(() {
        _ungroupedPurchasesCount = count;
      });
    });
  }

  @override
  void dispose() {
    _groupsSub?.cancel();
    _ungroupedPurchasesCountSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();
    final purchasesRepo = context.read<PurchasesRepository>();

    bool hasPurchases = _ungroupedPurchasesCount > 0;
    bool hasGroups = _groups.isNotEmpty;
    // If groups enabled or has groups, show groups
    // If no purchases and groups enabled, show groups
    bool onlyGroups = (!hasPurchases && hasGroups);
    bool showGroups = (hasGroups || settings.isGroupEnabled) || onlyGroups;
    // If purchases and groups disabled, show purchases
    bool onlyPurchases = (!settings.isGroupEnabled && !hasGroups);
    bool showPurchases = hasPurchases || onlyPurchases;
    // If both enabled, show titles
    bool showTitles = showGroups && showPurchases;

    // TODO: Create this Full Empty Screen with instructions/eastereggs
    // This screen contains two buttons FAB for purchase and + group
    // bool completeVoid = !hasPurchases && !hasGroups;

    const double groupTileHeight = 150;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart Ops'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ItemsScreen(group: null)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
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
          final purchase = await purchasesRepo.createPurchase(null);
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PurchasedItemsScreen(purchase: purchase, group: null),
              ),
            );
          }
        },
      ),
      floatingActionButtonLocation: settings.dominantHand == DominantHand.right
          ? FloatingActionButtonLocation.endFloat
          : settings.dominantHand == DominantHand.left
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.centerFloat,
      body: CustomScrollView(
        slivers: [
          if (showTitles)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              sliver: SliverToBoxAdapter(
                child: Text('Groups', style: Theme.of(context).textTheme.headlineSmall),
              ),
            ),

          if (showGroups) ...[
            if (_isLoadingGroups)
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: groupTileHeight,
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (onlyGroups)
              ..._buildGroupsOnlySlivers(context, colorScheme)
            else
              SliverToBoxAdapter(child: _buildGroupsView(context, colorScheme, groupTileHeight)),
          ],

          const SliverPadding(padding: EdgeInsets.only(top: 18)),

          if (showTitles)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text('Purchases', style: Theme.of(context).textTheme.headlineSmall),
              ),
            ),

          if (showPurchases) PurchasesList(stream: purchasesRepo.watchPurchases(), group: null),
        ],
      ),
    );
  }

  Widget _buildGroupTile(BuildContext context, Group group, ColorScheme colorScheme) {
    return Card.filled(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PurchasesScreen(group: group)),
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
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => _confirmDeleteGroup(context, group),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsView(BuildContext context, ColorScheme colorScheme, double groupTileHeight) {
    return SizedBox(
      height: groupTileHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _groups.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          if (index == _groups.length) {
            return SizedBox(
              width: groupTileHeight,
              child: _buildAddGroupTile(context, colorScheme),
            );
          }
          return SizedBox(
            width: groupTileHeight,
            child: _buildGroupTile(context, _groups[index], colorScheme),
          );
        },
      ),
    );
  }

  List<Widget> _buildGroupsOnlySlivers(BuildContext context, ColorScheme colorScheme) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Icon(Icons.storefront, size: 80, color: colorScheme.surfaceTint),
              const SizedBox(height: 24),
              Text(
                'Your Groups',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'All your purchases are organized in groups',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Two columns
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1, // Square tiles
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index == _groups.length) {
              return _buildAddGroupTile(context, colorScheme);
            }
            return _buildGroupTile(context, _groups[index], colorScheme);
          }, childCount: _groups.length + 1),
        ),
      ),
      // Add extra padding at the bottom so the FAB doesn't overlay the bottom grid item
      const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
    ];
  }

  Widget _buildAddGroupTile(BuildContext context, ColorScheme colorScheme) {
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showDialog(context: context, builder: (_) => const AddGroupDialog()),
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
}
