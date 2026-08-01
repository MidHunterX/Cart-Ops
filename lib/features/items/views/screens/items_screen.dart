import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/widgets/delete_confirmation_dialog.dart';
import 'package:shopping_assist/core/widgets/empty_state.dart';
import 'package:shopping_assist/core/widgets/dextrous_fab.dart';
import 'package:shopping_assist/core/widgets/item_image_view.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';
import 'package:shopping_assist/features/items/views/widgets/add_item_dialog.dart';
import 'package:shopping_assist/features/items/views/widgets/edit_item_dialog.dart';
import 'package:shopping_assist/features/items/views/screens/item_detail_screen.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import 'package:shopping_assist/features/settings/data/settings_data.dart';

class ItemsScreen extends StatefulWidget {
  final Group? group;

  const ItemsScreen({super.key, this.group});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  // Search feature
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ItemsRepository>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
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
                  const Text('Tracked Items'),
                  if (widget.group != null)
                    Text(widget.group!.name, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
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
        ],
      ),
      body: StreamBuilder<List<Item>>(
        stream: widget.group == null
            ? repo.watchItemsWithoutGroup()
            : repo.watchItemsInGroup(widget.group!.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allItems = snapshot.data ?? [];

          final items = _filterItems(allItems);

          if (items.isEmpty) {
            return EmptyState(
              icon: _isSearching ? Icons.search_off_outlined : Icons.inventory_2_outlined,
              title: _isSearching ? 'No Matching Items' : 'No Items Yet',
              message: _isSearching
                  ? 'Try entering a different item name.'
                  : 'Start by adding a new item to this list.',
            );
          }

          final zeroPurchaseItems = <Item>[];
          final multiplePurchaseItems = <Item>[];
          final singlePurchaseItems = <Item>[];

          return FutureBuilder<Map<int, int>>(
            future: _fetchPurchaseCounts(repo, items),
            builder: (context, countSnapshot) {
              if (countSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final purchaseCounts = countSnapshot.data ?? {};

              for (final item in items) {
                final count = purchaseCounts[item.id] ?? 0;
                if (count == 0) {
                  zeroPurchaseItems.add(item);
                } else if (count == 1) {
                  singlePurchaseItems.add(item);
                } else {
                  multiplePurchaseItems.add(item);
                }
              }

              return CustomScrollView(
                slivers: [
                  if (multiplePurchaseItems.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
                      sliver: _buildGridItems(multiplePurchaseItems, repo),
                    ),

                  if (singlePurchaseItems.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
                      sliver: _buildCompactList(singlePurchaseItems, repo),
                    ),

                  if (zeroPurchaseItems.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.only(left: 8, right: 8),
                      sliver: _buildZeroPurchasePanel(context, zeroPurchaseItems, repo),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)), // FAB Accomodation
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: DextrousFloatingActionButton(
        isCenter: context.dominantHand == DominantHand.center,
        icon: Icons.inventory_2_outlined,
        label: 'Add Item',
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AddItemDialog(groupId: widget.group?.id),
        ),
      ),
      floatingActionButtonLocation: context.dominantHand == DominantHand.right
          ? FloatingActionButtonLocation.endFloat
          : context.dominantHand == DominantHand.left
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.centerFloat,
    );
  }

  List<Item> _filterItems(List<Item> items) {
    if (_searchQuery.trim().isEmpty) return items;
    final query = _searchQuery.trim().toLowerCase();
    return items.where((item) {
      return item.name.toLowerCase().contains(query);
    }).toList();
  }

  Future<Map<int, int>> _fetchPurchaseCounts(ItemsRepository repo, List<Item> items) async {
    final Map<int, int> counts = {};
    for (final item in items) {
      final count = await repo.countPurchasesForItem(item.id);
      counts[item.id] = count;
    }
    return counts;
  }

  Widget _buildZeroPurchasePanel(BuildContext context, List<Item> items, ItemsRepository repo) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = items[index];
        return _buildCompactItemTile(context, item, repo, hasNoPurchases: true);
      }, childCount: items.length),
    );
  }

  Widget _buildGridItems(List<Item> items, ItemsRepository repo) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = items[index];
        return _buildItemCard(context, item, repo);
      }, childCount: items.length),
    );
  }

  Widget _buildCompactList(List<Item> items, ItemsRepository repo) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = items[index];
        return _buildCompactItemTile(context, item, repo);
      }, childCount: items.length),
    );
  }

  Widget _buildCompactItemTile(
    BuildContext context,
    Item item,
    ItemsRepository repo, {
    bool hasNoPurchases = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<int>(
      future: repo.countPurchasesForItem(item.id),
      builder: (context, snap) {
        final purchaseCount = snap.data ?? 0;

        return Card(
          color: hasNoPurchases ? colorScheme.errorContainer : null,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: SizedBox(
              width: 48,
              height: 48,
              child: ItemImageView(
                imagePath: item.imagePath,
                width: 48,
                height: 48,
                borderRadius: BorderRadius.circular(8),
                placeholderIcon: hasNoPurchases ? Icons.broken_image : Icons.inventory_2_rounded,
                placeholderIconColor: hasNoPurchases ? colorScheme.onError : null,
                placeholderIconBackgroundColor: hasNoPurchases ? colorScheme.error : null,
                placeholderIconSize: 24,
              ),
            ),
            title: Text(
              item.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium!.copyWith(color: hasNoPurchases ? colorScheme.error : null),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Bought $purchaseCount time${purchaseCount == 1 ? '' : 's'}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(color: hasNoPurchases ? colorScheme.error : null),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              iconColor: hasNoPurchases ? colorScheme.error : null,
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditDialog(context, item);
                } else if (value == 'delete') {
                  _confirmDelete(context, repo, item);
                }
              },
              itemBuilder: (ctx) => [
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
              MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
            ),
            onLongPress: () => _showEditDialog(context, item),
          ),
        );
      },
    );
  }

  Widget _buildItemCard(BuildContext context, Item item, ItemsRepository repo) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<int>(
      future: repo.countPurchasesForItem(item.id),
      builder: (context, snap) {
        final purchaseCount = snap.data;
        final hasNoPurchases = purchaseCount == 0;

        return Card.filled(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: hasNoPurchases
                ? null // Disable tap when no purchases
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
                  ),
            onLongPress: () => _showEditDialog(context, item),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildItemImage(item.imagePath, colorScheme, hasNoPurchases: hasNoPurchases),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20),
                            padding: EdgeInsets.zero,
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditDialog(context, item);
                              } else if (value == 'delete') {
                                _confirmDelete(context, repo, item);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
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
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bought $purchaseCount time${purchaseCount == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: hasNoPurchases ? colorScheme.error : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemImage(
    String? imagePath,
    ColorScheme colorScheme, {
    bool hasNoPurchases = false,
  }) {
    return ItemImageView(
      imagePath: imagePath,
      width: double.infinity,
      height: double.infinity,
      borderRadius: BorderRadius.zero,
      placeholderIcon: hasNoPurchases ? Icons.broken_image : Icons.inventory_2_rounded,
      placeholderIconSize: 48,
      placeholderIconColor: hasNoPurchases ? colorScheme.onError : null,
      placeholderIconBackgroundColor: hasNoPurchases ? colorScheme.error : null,
    );
  }

  void _showEditDialog(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (_) => EditItemDialog(item: item),
    );
  }

  void _confirmDelete(BuildContext context, ItemsRepository repo, Item item) {
    DeleteConfirmationDialog.show(
      context,
      title: 'Delete Item?',
      message: 'Are you sure you want to delete "${item.name}"?',
      onDelete: () async {
        try {
          await repo.deleteItem(item.id);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot delete item because it has been purchased before.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
    );
  }
}
