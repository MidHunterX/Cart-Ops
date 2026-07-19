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
    final textTheme = Theme.of(context).textTheme;
    final purchasesRepo = context.read<PurchasesRepository>();

    bool hasPurchases = _ungroupedPurchasesCount > 0;
    bool hasGroups = _groups.isNotEmpty;

    // LOGIC FOR COMBINATIONS
    bool onlyGroups = (!hasPurchases && hasGroups);
    bool showGroups = (hasGroups || context.isGroupEnabled) || onlyGroups;
    // If purchases and groups disabled, show purchases
    bool onlyPurchases = (!context.isGroupEnabled && !hasGroups);
    bool showPurchases = hasPurchases || onlyPurchases;
    // If both enabled, show titles
    bool showTitles = showGroups && showPurchases;
    // Complete Void (Full Empty Screen)
    bool completeVoid = !hasPurchases && !hasGroups && !_isLoadingGroups;

    const double groupTileHeight = 160;

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
        isCenter: context.dominantHand == DominantHand.center,
        icon: Icons.shopping_cart_checkout,
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
      floatingActionButtonLocation: context.dominantHand == DominantHand.right
          ? FloatingActionButtonLocation.endFloat
          : context.dominantHand == DominantHand.left
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.centerFloat,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          if (completeVoid)
            _buildEmptyStateSliver(context, colorScheme, textTheme, context.isGroupEnabled)
          else ...[
            if (showTitles)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Groups',
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
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
                ..._buildGroupsOnlySlivers(context, colorScheme, textTheme)
              else
                SliverToBoxAdapter(child: _buildGroupsView(context, colorScheme, groupTileHeight)),
            ],

            if (showTitles)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Purchases',
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            if (showPurchases) PurchasesList(stream: purchasesRepo.watchPurchases(), group: null),
          ],

          // bottom padding for FAB
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildGroupTile(BuildContext context, Group group, ColorScheme colorScheme) {
    return Card.filled(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PurchasesScreen(group: group)),
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.storefront, size: 36, color: colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      group.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: colorScheme.onSurfaceVariant),
                tooltip: 'Group Options',
                onSelected: (value) {
                  if (value == 'delete') _confirmDeleteGroup(context, group);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: colorScheme.error, size: 20),
                        const SizedBox(width: 12),
                        Text('Delete Group', style: TextStyle(color: colorScheme.error)),
                      ],
                    ),
                  ),
                ],
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
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
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

  List<Widget> _buildGroupsOnlySlivers(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.storefront, size: 56, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: 24),
              Text(
                'Your Groups',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'All your purchases are organized in groups',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index == _groups.length) {
              return _buildAddGroupTile(context, colorScheme);
            }
            return _buildGroupTile(context, _groups[index], colorScheme);
          }, childCount: _groups.length + 1),
        ),
      ),
    ];
  }

  Widget _buildAddGroupTile(BuildContext context, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.4), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showDialog(context: context, builder: (_) => const AddGroupDialog()),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, size: 28, color: colorScheme.primary),
              ),
              const SizedBox(height: 12),
              Text(
                'Add Group',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateSliver(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isEasterEgg,
  ) {
    final purchasesRepo = context.read<PurchasesRepository>();
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_mosaic_outlined,
              size: 80,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              isEasterEgg ? 'Welcome to the Real World!' : 'Welcome to Cart Ops!',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            isEasterEgg
                ? Text(
                    'You tap the blue pill, You go back shopping. '
                    'You tap the red pill, You live the structured life. '
                    'And I show you how deep the rabbit hole goes.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                  )
                : Text(
                    'Start organizing your shopping easily.'
                    'Add your first purchase below.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
            const SizedBox(height: 16),
            if (isEasterEgg)
              Stack(
                children: [
                  Opacity(
                    opacity: 0.4,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 60,
                      children: [
                        Transform.scale(
                          scaleY: -1,
                          child: const Text('🤚', style: TextStyle(fontSize: 90)),
                        ),
                        Transform.scale(
                          scaleX: -1,
                          scaleY: -1,
                          child: const Text('🤚', style: TextStyle(fontSize: 90)),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.create_new_folder_outlined),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        label: const Text('Groups'),
                        onPressed: () =>
                            showDialog(context: context, builder: (_) => const AddGroupDialog()),
                      ),
                      SizedBox(height: 60),
                      FilledButton.icon(
                        icon: const Icon(Icons.add_shopping_cart_outlined),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        label: const Text('Purchase'),
                        onPressed: () async {
                          final purchase = await purchasesRepo.createPurchase(null);
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PurchasedItemsScreen(purchase: purchase, group: null),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
          ],
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
