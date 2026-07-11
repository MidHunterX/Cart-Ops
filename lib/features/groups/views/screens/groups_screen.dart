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
  bool _isLoadingGroups = true;

  @override
  void initState() {
    super.initState();
    final groupsRepo = context.read<GroupsRepository>();

    _groupsSub = groupsRepo.watchGroups().listen((newGroups) {
      if (!mounted) return;
      setState(() {
        _groups = newGroups;
        _isLoadingGroups = false;
      });
    });
  }

  @override
  void dispose() {
    _groupsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();
    final purchasesRepo = context.read<PurchasesRepository>();

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
          final purchase = await purchasesRepo.createPurchase(null);
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
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            sliver: SliverToBoxAdapter(
              child: Text('Groups', style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          SliverToBoxAdapter(
            child: _isLoadingGroups
                ? const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()))
                : SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _groups.length + 1,
                      separatorBuilder: (context, index) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        if (index == _groups.length) {
                          return SizedBox(
                            width: 150,
                            child: _buildAddGroupTile(context, colorScheme),
                          );
                        }
                        return SizedBox(
                          width: 150,
                          child: _buildGroupTile(context, _groups[index], colorScheme),
                        );
                      },
                    ),
                  ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text('General Purchases', style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 80),
            sliver: PurchasesList(stream: purchasesRepo.watchGeneralPurchases(), group: null),
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
}
