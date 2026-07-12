import 'package:flutter/material.dart';
import 'package:shopping_assist/features/settings/data/settings_data.dart';

class ThemeColorPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const ThemeColorPicker({super.key, required this.selectedColor, required this.onColorSelected});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double colorSwatchSize = (screenWidth * 0.1).clamp(24, 48);
    final double spacing = (screenWidth * 0.04).clamp(8, 12);

    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: colorOptions.map((color) {
          final isSelected = selectedColor.toARGB32() == color.toARGB32();

          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              width: colorSwatchSize,
              height: colorSwatchSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2)
                    : null,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}
