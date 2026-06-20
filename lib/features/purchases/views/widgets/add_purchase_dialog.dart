import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/features/purchases/repositories/purchases_repository.dart';

class AddPurchaseDialog extends StatefulWidget {
  final int? groupId;

  const AddPurchaseDialog({super.key, required this.groupId});

  @override
  State<AddPurchaseDialog> createState() => _AddPurchaseDialogState();
}

class _AddPurchaseDialogState extends State<AddPurchaseDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      context.read<PurchasesRepository>().addPurchase(name, widget.groupId);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Purchase Event'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: 'e.g. Weekend Groceries'),
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
