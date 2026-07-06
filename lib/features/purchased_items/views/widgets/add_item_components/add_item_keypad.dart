import 'package:flutter/material.dart';

class AddItemKeypad extends StatelessWidget {
  final bool isLoading;
  final String itemName;
  final bool hasImage;
  final String discountStr;
  final bool isTeleKeypad;
  final Function(String) onKeyPressed;
  final VoidCallback onNameTap;
  final VoidCallback onImageTap;
  final VoidCallback onDiscountTap;
  final VoidCallback onSubmit;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const AddItemKeypad({
    super.key,
    required this.isLoading,
    required this.itemName,
    required this.hasImage,
    required this.discountStr,
    required this.isTeleKeypad,
    required this.onKeyPressed,
    required this.onNameTap,
    required this.onImageTap,
    required this.onDiscountTap,
    required this.onSubmit,
    required this.onIncrement,
    required this.onDecrement,
  });

  Widget _buildActionBtn({
    String? text,
    IconData? icon,
    required VoidCallback onTap,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: EdgeInsets.zero,
            elevation: 0,
          ),
          child: SizedBox(
            height: 56,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 24),
                      if (text != null && text.isNotEmpty) const SizedBox(width: 8),
                    ],
                    if (text != null && text.isNotEmpty)
                      Flexible(
                        child: Text(
                          text,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumBtn(BuildContext context, String text) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: OutlinedButton(
          onPressed: () => onKeyPressed(text),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: EdgeInsets.zero,
          ),
          child: SizedBox(
            height: 56,
            child: Center(child: Text(text, style: Theme.of(context).textTheme.titleMedium)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    bool hasDiscount = discountStr.isNotEmpty && discountStr != '0';
    bool hasText = itemName.isNotEmpty;

    // SEMANTIC HIERARCHY DEFINITIONS
    // ------------------------------
    // High Emphasis (Primary Action)
    Color mainActionBg = colorScheme.primary;
    Color mainActionFg = colorScheme.onPrimary;

    // Medium Emphasis (Active Inputs / Primary Utilities)
    Color inputActiveBg = colorScheme.primaryContainer;
    Color inputActiveFg = colorScheme.onPrimaryContainer;

    // Accent Emphasis (Secondary Utilities / Modifiers)
    Color functionalBg = colorScheme.secondaryContainer;
    Color functionalFg = colorScheme.onSecondaryContainer;

    // Low Emphasis (Inactive / Surface / Numbers)
    Color inputInactiveBg = colorScheme.surfaceContainerHighest;
    Color inputInactiveFg = colorScheme.onSurfaceVariant;

    // Alert Emphasis (Destructive)
    Color destructiveBg = colorScheme.errorContainer;
    Color destructiveFg = colorScheme.onErrorContainer;

    return Column(
      children: [
        Row(
          children: [
            _buildActionBtn(
              text: isLoading ? 'Loading...' : (hasText ? itemName : 'Name'),
              backgroundColor: hasText ? inputActiveBg : inputInactiveBg,
              foregroundColor: hasText ? inputActiveFg : inputInactiveFg,
              onTap: isLoading ? () {} : onNameTap,
            ),
            _buildActionBtn(
              text: !hasImage ? 'Image' : 'Img Added',
              icon: !hasImage ? null : Icons.check_circle,
              backgroundColor: hasImage ? inputActiveBg : inputInactiveBg,
              foregroundColor: hasImage ? inputActiveFg : inputInactiveFg,
              onTap: onImageTap,
            ),
            _buildActionBtn(
              text: hasDiscount ? 'Disc: $discountStr' : 'Discount',
              backgroundColor: hasDiscount ? inputActiveBg : inputInactiveBg,
              foregroundColor: hasDiscount ? inputActiveFg : inputInactiveFg,
              onTap: onDiscountTap,
            ),
            _buildActionBtn(
              text: 'OK',
              backgroundColor: mainActionBg,
              foregroundColor: mainActionFg,
              onTap: onSubmit,
            ),
          ],
        ),
        Row(
          children: [
            _buildNumBtn(context, isTeleKeypad ? '1' : '7'),
            _buildNumBtn(context, isTeleKeypad ? '2' : '8'),
            _buildNumBtn(context, isTeleKeypad ? '3' : '9'),
            _buildActionBtn(
              icon: Icons.backspace_outlined,
              backgroundColor: functionalBg,
              foregroundColor: functionalFg,
              onTap: () => onKeyPressed('<='),
            ),
          ],
        ),
        Row(
          children: [
            _buildNumBtn(context, '4'),
            _buildNumBtn(context, '5'),
            _buildNumBtn(context, '6'),
            _buildActionBtn(
              text: 'C',
              backgroundColor: destructiveBg,
              foregroundColor: destructiveFg,
              onTap: () => onKeyPressed('C'),
            ),
          ],
        ),
        Row(
          children: [
            _buildNumBtn(context, isTeleKeypad ? '7' : '1'),
            _buildNumBtn(context, isTeleKeypad ? '8' : '2'),
            _buildNumBtn(context, isTeleKeypad ? '9' : '3'),
            _buildActionBtn(
              text: '—',
              backgroundColor: functionalBg,
              foregroundColor: functionalFg,
              onTap: () => onKeyPressed('-'),
            ),
          ],
        ),
        Row(
          children: [
            _buildNumBtn(context, isTeleKeypad ? '.' : '0'),
            _buildNumBtn(context, isTeleKeypad ? '0' : '.'),
            _buildNumBtn(context, '.99'),
            _buildActionBtn(
              icon: Icons.keyboard_tab,
              backgroundColor: functionalBg,
              foregroundColor: functionalFg,
              onTap: () => onKeyPressed('=>'),
            ),
          ],
        ),
      ],
    );
  }
}
