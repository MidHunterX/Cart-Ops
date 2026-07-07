import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_assist/features/purchased_items/utils/keypad_logic.dart';

void main() {
  group('KeypadLogic', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('Handles standard character input correctly', () {
      KeypadLogic.handleInput(controller, '1');
      expect(controller.text, '1');

      KeypadLogic.handleInput(controller, '2');
      expect(controller.text, '12');
    });

    test('Handles clear (C)', () {
      controller.text = '123';
      KeypadLogic.handleInput(controller, 'C');
      expect(controller.text, '');
    });

    test('Handles backspace (<=) at end of string', () {
      controller.text = '123';
      controller.selection = const TextSelection.collapsed(offset: 3);
      KeypadLogic.handleInput(controller, '<=');
      expect(controller.text, '12');
    });

    test('Handles backspace (<=) with active selection range', () {
      controller.text = '12345';
      controller.selection = const TextSelection(baseOffset: 1, extentOffset: 4);
      KeypadLogic.handleInput(controller, '<=');
      expect(controller.text, '15'); // Removed '234'
    });

    test('Handles .99 shortcut', () {
      // Append to integer
      controller.text = '5';
      KeypadLogic.handleInput(controller, '.99');
      expect(controller.text, '5.99');

      // Replace existing decimal fraction
      controller.text = '5.50';
      KeypadLogic.handleInput(controller, '.99');
      expect(controller.text, '5.99');

      // Empty prefix
      controller.text = '';
      KeypadLogic.handleInput(controller, '.99');
      expect(controller.text, '0.99');
    });

    test('Handles negative toggle (-)', () {
      controller.text = '5';
      KeypadLogic.handleInput(controller, '-');
      expect(controller.text, '-5');

      KeypadLogic.handleInput(controller, '-');
      expect(controller.text, '5'); // Toggles back to positive
    });

    test('Prevents multiple decimals', () {
      controller.text = '5.';
      KeypadLogic.handleInput(controller, '.');
      expect(controller.text, '5.');
    });
  });
}
