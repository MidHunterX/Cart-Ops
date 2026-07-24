import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/features/groups/repositories/groups_repository.dart';

// Tree-shakable static icon registry
const Map<String, IconData> groupIcons = {
  'storefront': Icons.storefront,
  'favorite': Icons.favorite,
  'grocery': Icons.local_grocery_store,
  'restaurant': Icons.restaurant,
  'pharmacy': Icons.local_pharmacy,
  'build': Icons.build,
  'checkroom': Icons.checkroom,
  'devices': Icons.devices,
  'menu_book': Icons.menu_book,
  'sports_basketball': Icons.sports_basketball,
  'pets': Icons.pets,
  'directions_car': Icons.directions_car,
  'redeem': Icons.redeem,
  'brush': Icons.brush,
  'home': Icons.home,
};

/// Dynamic icon lookup with fallback to storefront
IconData getGroupIcon(String? iconKey) {
  return groupIcons[iconKey] ?? Icons.storefront;
}

class AddGroupDialog extends StatefulWidget {
  final Group? group; // Triggers Edit mode if non-null
  const AddGroupDialog({super.key, this.group});
  @override
  State<AddGroupDialog> createState() => _AddGroupDialogState();
}

class _AddGroupDialogState extends State<AddGroupDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedIconKey = 'storefront';

  bool get _isEditing => widget.group != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.group!.name;
      _descController.text = widget.group!.description ?? '';
      _selectedIconKey = widget.group!.iconKey ?? 'storefront';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final description = _descController.text.trim();
    if (name.isNotEmpty) {
      final repo = context.read<GroupsRepository>();
      if (_isEditing) {
        repo.updateGroup(
          widget.group!.id,
          name,
          description: description.isEmpty ? null : description,
          iconKey: _selectedIconKey,
        );
      } else {
        repo.addGroup(
          name,
          description: description.isEmpty ? null : description,
          iconKey: _selectedIconKey,
        );
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Shopping Group' : 'New Shopping Group'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'e.g. Hypermarket, Hardware Store',
                  border: OutlineInputBorder(),
                ),
                autofocus: !_isEditing,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g. Weekly grocery run',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Text('Select Group Icon', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              SizedBox(
                height: 130,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: groupIcons.length,
                  itemBuilder: (context, index) {
                    final key = groupIcons.keys.elementAt(index);
                    final icon = groupIcons[key]!;
                    final isSelected = key == _selectedIconKey;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIconKey = key;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          border: Border.all(
                            color: isSelected ? colorScheme.primary : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: Text(_isEditing ? 'Save' : 'Add')),
      ],
    );
  }
}
