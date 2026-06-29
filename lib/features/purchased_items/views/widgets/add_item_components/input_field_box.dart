import 'package:flutter/material.dart';

enum ActiveField { quantity, price }

class InputFieldBox extends StatelessWidget {
  final String label;
  final String value;
  final bool isActive;
  final VoidCallback onTap;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  const InputFieldBox({
    super.key,
    required this.label,
    required this.value,
    required this.isActive,
    required this.onTap,
    this.controller,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: onTap,
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          readOnly: true,
          showCursor: true,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: textTheme.bodySmall?.copyWith(
              color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isActive ? colorScheme.primary : colorScheme.outline,
                width: isActive ? 2 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isActive ? colorScheme.primary : colorScheme.outline,
                width: isActive ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            filled: isActive,
            fillColor: isActive ? colorScheme.primaryContainer : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
