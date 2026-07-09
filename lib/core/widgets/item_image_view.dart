import 'dart:io';
import 'package:flutter/material.dart';

/// A widget that displays an image, with a placeholder icon if the image is not found
///
/// heroTag: unique identifier for the image, used for animated transition
/// enableTapToView: if true, the image can be tapped to view it
class ItemImageView extends StatelessWidget {
  final String? imagePath;
  final double? width;
  final double? height;
  final double? size;
  final IconData placeholderIcon;
  final double? placeholderIconSize;
  final BorderRadius? borderRadius;
  final String? heroTag;
  final bool enableTapToView;

  const ItemImageView({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.size,
    this.placeholderIcon = Icons.shopping_bag_outlined,
    this.placeholderIconSize,
    this.borderRadius,
    this.heroTag,
    this.enableTapToView = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final w = width ?? size;
    final h = height ?? size;
    final br = borderRadius ?? BorderRadius.circular(8);
    final pSize = placeholderIconSize ?? (w != null ? w * 0.6 : 24.0);

    final hasImage = imagePath != null && File(imagePath!).existsSync();

    Widget imageWidget = Container(
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

    if (hasImage && heroTag != null) {
      imageWidget = Hero(tag: heroTag!, child: imageWidget);
    }

    if (hasImage && enableTapToView) {
      return InkWell(
        onTap: () => _showFullScreenImage(context),
        borderRadius: br,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  void _showFullScreenImage(BuildContext context) {
    if (imagePath == null) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullScreenImageView(
            imagePath: imagePath!,
            heroTag: heroTag,
            onDismiss: () => Navigator.of(context).pop(),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

class FullScreenImageView extends StatelessWidget {
  final String imagePath;
  final String? heroTag;
  final VoidCallback onDismiss;

  const FullScreenImageView({
    super.key,
    required this.imagePath,
    this.heroTag,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onDismiss,
              // Flashbang Warning!
              // splashColor: colorScheme.primary,
              // highlightColor: colorScheme.onSurfaceVariant,
              child: Center(
                child: heroTag != null
                    ? Hero(
                        tag: heroTag!,
                        child: Image.file(
                          File(imagePath),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.image_not_supported, color: Colors.white, size: 64),
                        ),
                      )
                    : Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.image_not_supported, color: Colors.white, size: 64),
                      ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: onDismiss,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              ),
            ),
          ),

          // Hint text at bottom
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Tap anywhere to close',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
