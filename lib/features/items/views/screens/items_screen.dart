import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/widgets/delete_confirmation_dialog.dart';
import 'package:shopping_assist/core/widgets/empty_state.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';
import 'package:shopping_assist/features/items/views/widgets/add_item_dialog.dart';
import 'package:shopping_assist/features/items/views/widgets/edit_item_dialog.dart';
import 'package:shopping_assist/features/items/views/screens/item_detail_screen.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import 'package:shopping_assist/features/settings/data/settings_data.dart';

class ItemsScreen extends StatelessWidget {
  final Group? group;

  const ItemsScreen({super.key, this.group});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final repo = context.watch<ItemsRepository>();
    final title = group == null ? 'General Items' : '${group!.name} Items';
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: colorScheme.primaryContainer),
      body: StreamBuilder<List<Item>>(
        stream: group == null ? repo.watchItemsWithoutGroup() : repo.watchItemsInGroup(group!.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No Items Yet',
              message: 'Start by adding a new item to this list.',
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildItemCard(context, item, repo);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AddItemDialog(groupId: group?.id),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      floatingActionButtonLocation: settings.dominantHand == DominantHand.right
          ? FloatingActionButtonLocation.endFloat
          : settings.dominantHand == DominantHand.left
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildItemCard(BuildContext context, Item item, ItemsRepository repo) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias, // Internal image doesn't overflow the rounded corners
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildItemImage(item.imagePath, colorScheme),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.8),
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
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
                  FutureBuilder<int>(
                    future: repo.countPurchasesForItem(item.id),
                    builder: (ctx, snap) {
                      final count = snap.data ?? 0;
                      return Text(
                        'Bought $count time${count == 1 ? '' : 's'}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage(String? imagePath, ColorScheme colorScheme) {
    if (imagePath != null && File(imagePath).existsSync()) {
      return Image.file(File(imagePath), fit: BoxFit.cover);
    }
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.inventory_2_rounded, size: 48, color: colorScheme.onSurfaceVariant),
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
