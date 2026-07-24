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

  void _showEditGroupDialog(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder: (_) => AddGroupDialog(group: group),
    );
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

    final bool hasPurchases = _ungroupedPurchasesCount > 0;
    final bool hasGroups = _groups.isNotEmpty;

    // LOGIC FOR COMBINATIONS
    final bool isGroupEnabled = context.isGroupEnabled;
    final bool onlyGroups = (!hasPurchases && hasGroups);
    final bool showGroups = (hasGroups || isGroupEnabled) || onlyGroups;
    // If purchases and groups disabled, show purchases
    final bool onlyPurchases = (!isGroupEnabled && !hasGroups);
    final bool showPurchases = hasPurchases || onlyPurchases;
    // If both enabled, show titles
    final bool showTitles = showGroups && showPurchases;
    // Complete Void (Full Empty Screen)
    final bool completeVoid = !hasPurchases && !hasGroups && !_isLoadingGroups;

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
            _buildEmptyStateSliver(context, colorScheme, textTheme, isGroupEnabled)
          else ...[
            if (showTitles) _SliverHeader(title: 'Groups', textTheme: textTheme),

            if (onlyGroups)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 32.0, bottom: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.storefront,
                          size: 56,
                          color: colorScheme.onPrimaryContainer,
                        ),
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

            if (showGroups)
              _isLoadingGroups
                  ? const SliverToBoxAdapter(
                      child: SizedBox(
                        height: groupTileHeight,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  : onlyGroups
                  ? SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: _buildGroupsGrid(colorScheme),
                    )
                  : SliverToBoxAdapter(
                      child: RepaintBoundary(
                        child: _buildGroupsHorizontalList(colorScheme, groupTileHeight),
                      ),
                    ),

            if (showTitles) _SliverHeader(title: 'Purchases', textTheme: textTheme),

            if (showPurchases) PurchasesList(stream: purchasesRepo.watchPurchases(), group: null),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildGroupsGrid(ColorScheme colorScheme) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == _groups.length) return _buildAddGroupTile(context, colorScheme);
        return _buildGroupTile(context, _groups[index], colorScheme);
      }, childCount: _groups.length + 1),
    );
  }

  Widget _buildGroupsHorizontalList(ColorScheme colorScheme, double height) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        // Builder is more efficient than separated for small lists
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _groups.length + 1,
        itemBuilder: (context, index) {
          final isLast = index == _groups.length;
          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 16),
            child: SizedBox(
              width: height,
              child: isLast
                  ? _buildAddGroupTile(context, colorScheme)
                  : _buildGroupTile(context, _groups[index], colorScheme),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupTile(BuildContext context, Group group, ColorScheme colorScheme) {
    final iconData = getGroupIcon(group.iconKey);

    return Card.filled(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PurchasesScreen(group: group)),
        ),
        onLongPress: () => _showEditGroupDialog(context, group),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(iconData, size: 36, color: colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      group.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (group.description != null && group.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        group.description!,
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
                  if (value == 'edit') _showEditGroupDialog(context, group);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 12),
                        const Text('Edit Group'),
                      ],
                    ),
                  ),
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

class _SliverHeader extends StatelessWidget {
  final String title;
  final TextTheme textTheme;
  const _SliverHeader({required this.title, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      sliver: SliverToBoxAdapter(
        child: Text(title, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
