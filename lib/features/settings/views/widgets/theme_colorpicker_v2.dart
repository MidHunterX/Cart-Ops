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
      padding: const EdgeInsets.only(top: 12.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: colorOptions.map((color) {
          // Compare by ARGB value as dart sees it as different
          final isSelected = selectedColor.toARGB32() == color.toARGB32();

          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: ShapeDecoration(
                color: color,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: isSelected
                      ? BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3,
                        )
                      : BorderSide.none,
                ),
                shadows: [
                  if (isSelected)
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}
