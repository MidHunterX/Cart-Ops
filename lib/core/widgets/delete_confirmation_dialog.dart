import 'package:flutter/material.dart';

/// A reusable delete confirmation dialog with customizable content and actions.
class DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onDelete;
  final String? deleteButtonText;

  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onDelete,
    this.deleteButtonText = 'Delete',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
          onPressed: () {
            Navigator.pop(context);
            onDelete();
          },
          child: Text(deleteButtonText!),
        ),
      ],
    );
  }

  /// Convenience method to show the dialog.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onDelete,
    String deleteButtonText = 'Delete',
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => DeleteConfirmationDialog(
        title: title,
        message: message,
        onDelete: onDelete,
        deleteButtonText: deleteButtonText,
      ),
    );
  }
}
