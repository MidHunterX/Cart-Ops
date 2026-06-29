import 'package:flutter/material.dart';

class UnitQuantitySelector extends StatelessWidget {
  final String quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const UnitQuantitySelector({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _buildButton(context, Icons.remove, onDecrement, isLeft: true),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  quantity,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            _buildButton(context, Icons.add, onIncrement, isLeft: false),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed, {
    required bool isLeft,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: isLeft ? const Radius.circular(8) : Radius.zero,
            bottomLeft: isLeft ? const Radius.circular(8) : Radius.zero,
            topRight: !isLeft ? const Radius.circular(8) : Radius.zero,
            bottomRight: !isLeft ? const Radius.circular(8) : Radius.zero,
          ),
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
