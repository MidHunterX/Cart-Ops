import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/features/groups/repositories/groups_repository.dart';

class AddGroupDialog extends StatefulWidget {
  const AddGroupDialog({super.key});

  @override
  State<AddGroupDialog> createState() => _AddGroupDialogState();
}

class _AddGroupDialogState extends State<AddGroupDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      context.read<GroupsRepository>().addGroup(name);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Shopping Group'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'e.g. Lulu Hypermarket, Hardware Store',
        ),
        autofocus: true,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
