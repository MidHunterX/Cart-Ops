import 'package:flutter/material.dart';

enum ActiveField { quantity, price }

class InputFieldBox extends StatelessWidget {
  final String label;
  final String value;
  final bool isActive;
  final int flex;
  final VoidCallback onTap;
  final Widget? customContent;

  const InputFieldBox({
    super.key,
    required this.label,
    required this.value,
    required this.isActive,
    required this.onTap,
    this.flex = 9,
    this.customContent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(8),
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive ? colorScheme.primary : colorScheme.outline,
              width: isActive ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isActive ? colorScheme.primaryContainer : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              if (customContent != null)
                Expanded(child: customContent!)
              else
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value.isEmpty ? '0' : value,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdjustButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const AdjustButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}
