import 'package:flutter/material.dart';

class AddItemKeypad extends StatelessWidget {
  final bool isLoading;
  final String itemName;
  final bool hasImage;
  final String discountStr;
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

    return Column(
      children: [
        Row(
          children: [
            _buildActionBtn(
              text: isLoading ? 'Loading...' : (itemName.isEmpty ? 'Name' : itemName),
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              onTap: isLoading ? () {} : onNameTap,
            ),
            _buildActionBtn(
              text: !hasImage ? 'Image' : 'Img Added',
              icon: !hasImage ? null : Icons.check_circle,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              onTap: onImageTap,
            ),
            _buildActionBtn(
              text: discountStr == '0' || discountStr.isEmpty ? 'Discount' : 'Disc: $discountStr',
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              onTap: onDiscountTap,
            ),
            _buildActionBtn(
              text: 'OK',
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              onTap: onSubmit,
            ),
          ],
        ),
        Row(
          children: [
            _buildNumBtn(context, '7'),
            _buildNumBtn(context, '8'),
            _buildNumBtn(context, '9'),
            _buildActionBtn(
              icon: Icons.backspace,
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
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
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
              onTap: () => onKeyPressed('C'),
            ),
          ],
        ),
        Row(
          children: [
            _buildNumBtn(context, '1'),
            _buildNumBtn(context, '2'),
            _buildNumBtn(context, '3'),
            _buildActionBtn(
              text: '-',
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
              onTap: () => onKeyPressed('-'),
            ),
          ],
        ),
        Row(
          children: [
            _buildNumBtn(context, '0'),
            _buildNumBtn(context, '.'),
            _buildNumBtn(context, '.99'),
            _buildActionBtn(
              icon: Icons.keyboard_tab,
              backgroundColor: colorScheme.onPrimary,
              foregroundColor: colorScheme.primary,
              onTap: () => onKeyPressed('=>'),
            ),
          ],
        ),
      ],
    );
  }
}
