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
  });

  Widget _buildActionBtn({
    required BuildContext context,
    String? text,
    IconData? icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 56,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: fg, size: 24),
                        if (text != null && text.isNotEmpty)
                          const SizedBox(width: 8),
                      ],
                      if (text != null && text.isNotEmpty)
                        Flexible(
                          child: Text(
                            text,
                            style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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
      ),
    );
  }

  Widget _buildNumBtn(BuildContext context, String text) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.zero,
          ),
          onPressed: () => onKeyPressed(text),
          child: SizedBox(
            height: 56,
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color redBg = isDark ? Colors.red.shade900 : Colors.red.shade100;
    Color redFg = isDark ? Colors.red.shade100 : Colors.red.shade900;
    Color greenBg = isDark ? Colors.green.shade900 : Colors.green.shade200;
    Color greenFg = isDark ? Colors.green.shade100 : Colors.green.shade900;
    Color blueBg = isDark ? Colors.blue.shade900 : Colors.blue.shade100;
    Color blueFg = isDark ? Colors.blue.shade100 : Colors.blue.shade900;

    return Column(
      children: [
        Row(
          children: [
            _buildActionBtn(
              context: context,
              text: isLoading
                  ? 'Loading...'
                  : (itemName.isEmpty ? 'Name' : itemName),
              bg: blueBg,
              fg: blueFg,
              onTap: isLoading ? () {} : onNameTap,
            ),
            _buildActionBtn(
              context: context,
              text: !hasImage ? 'Image' : 'Img Added',
              icon: !hasImage ? null : Icons.check_circle,
              bg: blueBg,
              fg: blueFg,
              onTap: onImageTap,
            ),
            _buildActionBtn(
              context: context,
              text: discountStr == '0' || discountStr.isEmpty
                  ? 'Discount'
                  : 'Disc: $discountStr',
              bg: blueBg,
              fg: blueFg,
              onTap: onDiscountTap,
            ),
            _buildActionBtn(
              context: context,
              text: 'OK',
              bg: greenBg,
              fg: greenFg,
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
              context: context,
              icon: Icons.backspace,
              bg: redBg,
              fg: redFg,
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
              context: context,
              text: 'C',
              bg: redBg,
              fg: redFg,
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
              context: context,
              text: '-',
              bg: redBg,
              fg: redFg,
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
              context: context,
              icon: Icons.keyboard_tab,
              bg: greenBg,
              fg: greenFg,
              onTap: () => onKeyPressed('=>'),
            ),
          ],
        ),
      ],
    );
  }
}
