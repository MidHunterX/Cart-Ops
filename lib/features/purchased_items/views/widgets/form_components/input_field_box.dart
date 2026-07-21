import 'package:flutter/material.dart';

enum ActiveField { quantity, price }

class InputFieldBox extends StatelessWidget {
  final String? label;
  final String value;
  final bool isActive;
  final VoidCallback onTap;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final String? prefixText;
  final String? suffixText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextAlign textAlign;

  const InputFieldBox({
    super.key,
    required this.value,
    required this.isActive,
    required this.onTap,
    this.label,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.prefixText,
    this.suffixText,
    this.prefixIcon,
    this.suffixIcon,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        readOnly: true,
        showCursor: true,
        textAlign: textAlign,
        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
        decoration: InputDecoration(
          labelText: label,
          hintText: placeholder,
          labelStyle: textTheme.bodySmall?.copyWith(
            color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: UnderlineInputBorder(
            borderSide: BorderSide(
              color: isActive ? colorScheme.primary : colorScheme.outline,
              width: isActive ? 2 : 1,
            ),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: isActive ? colorScheme.primary : colorScheme.outline,
              width: isActive ? 2 : 1,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          filled: true,
          fillColor: isActive ? colorScheme.primaryContainer : Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          prefixText: prefixText,
          suffixText: suffixText,
          prefixStyle: textTheme.bodySmall?.copyWith(fontSize: 16),
          suffixStyle: textTheme.bodySmall?.copyWith(fontSize: 16),
        ),
        onTap: onTap,
      ),
    );
  }
}
