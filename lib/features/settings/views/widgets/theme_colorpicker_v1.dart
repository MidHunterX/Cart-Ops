import 'package:flutter/material.dart';
import 'package:shopping_assist/features/settings/data/settings_data.dart';

class ThemeColorPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const ThemeColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Wrap(
        spacing: 12,
        children: colorOptions.map((color) {
          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: CircleAvatar(
                backgroundColor: color,
                radius: 20,
                child: selectedColor.toARGB32() == color.toARGB32()
                    ? const Icon(Icons.check, size: 16, color: Colors.black)
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
