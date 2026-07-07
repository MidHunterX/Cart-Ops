import 'dart:io';
import 'package:flutter/material.dart';

class ItemImageView extends StatelessWidget {
  final String? imagePath;
  final double? width;
  final double? height;
  final double? size;
  final IconData placeholderIcon;
  final double? placeholderIconSize;
  final BorderRadius? borderRadius;

  const ItemImageView({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.size,
    this.placeholderIcon = Icons.shopping_bag_outlined,
    this.placeholderIconSize,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final w = width ?? size;
    final h = height ?? size;
    final br = borderRadius ?? BorderRadius.circular(8);
    final pSize = placeholderIconSize ?? (w != null ? w * 0.6 : 24.0);

    final hasImage = imagePath != null && File(imagePath!).existsSync();

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: br),
      child: hasImage
          ? ClipRRect(
              borderRadius: br,
              child: Image.file(
                File(imagePath!),
                width: w,
                height: h,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.image_not_supported, color: colorScheme.onSurfaceVariant),
              ),
            )
          : Icon(placeholderIcon, color: colorScheme.onSurfaceVariant, size: pSize),
    );
  }
}
