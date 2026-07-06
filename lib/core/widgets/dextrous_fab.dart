import 'package:flutter/material.dart';

class DextrousFloatingActionButton extends StatelessWidget {
  final Future<void> Function()? onPressed;
  final IconData icon;
  final String label;
  final bool isCenter;
  final double? horizontalPadding;
  final double? bottomPadding;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const DextrousFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isCenter,
    this.horizontalPadding,
    this.bottomPadding,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final hPadding = horizontalPadding ?? 16.0;

    if (isCenter) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: hPadding),
        child: SizedBox(width: double.infinity, child: _buildFab(context)),
      );
    } else {
      return _buildFab(context);
    }
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }
}
