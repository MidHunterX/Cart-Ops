import 'package:flutter/material.dart';

class KeypadLogic {
  static void handleInput(TextEditingController controller, String val) {
    final text = controller.text;
    final selection = controller.selection;

    if (val == '<=') {
      if (selection.start == selection.end) {
        if (selection.start > 0) {
          final newText = text.replaceRange(selection.start - 1, selection.start, '');
          controller.value = controller.value.copyWith(
            text: newText,
            selection: TextSelection.collapsed(offset: selection.start - 1),
          );
        }
      } else {
        final newText = text.replaceRange(selection.start, selection.end, '');
        controller.value = controller.value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: selection.start),
        );
      }
      return;
    }

    if (val == 'C') {
      controller.clear();
      return;
    }

    if (val == '.99') {
      if (!text.contains('.')) {
        controller.text = text.isEmpty ? '0.99' : '$text.99';
      } else {
        final parts = text.split('.');
        controller.text = '${parts[0]}.99';
      }
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
      return;
    }

    if (val == '-') {
      if (text.startsWith('-')) {
        controller.text = text.substring(1);
      } else {
        controller.text = '-$text';
      }
      return;
    }

    if (val == '.' && text.contains('.')) return;

    final newText = text.replaceRange(
      selection.start != -1 ? selection.start : text.length,
      selection.end != -1 ? selection.end : text.length,
      val,
    );

    final newOffset = (selection.start != -1 ? selection.start : text.length) + val.length;

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
