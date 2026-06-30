import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/widgets/delete_confirmation_dialog.dart';
import 'package:shopping_assist/core/widgets/empty_state.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';
import 'package:shopping_assist/features/items/views/widgets/add_item_dialog.dart';

class ItemsScreen extends StatelessWidget {
  final Group? group;

  const ItemsScreen({super.key, this.group});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final repo = context.watch<ItemsRepository>();
    final title = group == null ? 'General Items' : '${group!.name} Items';

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

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.label_outline),
                    title: Text(item.name),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: colorScheme.error),
                      onPressed: () => _confirmDelete(context, repo, item),
                    ),
                  ),
                  if (index < items.length - 1) const Divider(height: 1),
                ],
              );
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
