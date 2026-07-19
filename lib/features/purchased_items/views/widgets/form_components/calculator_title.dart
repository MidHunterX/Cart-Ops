import 'package:flutter/material.dart';

class CalculatorTitle extends StatelessWidget {
  final String mainText;
  final IconData icon;

  const CalculatorTitle({super.key, required this.mainText, this.icon = Icons.calculate_outlined});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$mainText ',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
              TextSpan(
                text: 'Calculator',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
