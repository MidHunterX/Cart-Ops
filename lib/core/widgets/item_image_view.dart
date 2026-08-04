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
  final Color? placeholderIconColor;
  final Color? placeholderIconBackgroundColor;

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
    this.placeholderIconColor,
    this.placeholderIconBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final color = placeholderIconColor ?? colorScheme.onSurfaceVariant;
    final backgroundColor = placeholderIconBackgroundColor ?? colorScheme.surfaceContainerHighest;

    final w = width ?? size;
    final h = height ?? size;
    final br = borderRadius ?? BorderRadius.circular(8);

    final pSize = (placeholderIconSize != null && placeholderIconSize!.isFinite)
        ? placeholderIconSize!
        : (w != null && w.isFinite ? w * 0.6 : 24.0);

    final hasImage = imagePath != null && File(imagePath!).existsSync();

    Widget imageWidget = Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: backgroundColor, borderRadius: br),
      child: hasImage
          ? ClipRRect(
              borderRadius: br,
              child: Image.file(
                File(imagePath!),
                width: w,
                height: h,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(Icons.image_not_supported, color: color),
              ),
            )
          : Icon(placeholderIcon, color: color, size: pSize),
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
          return FullScreenImageView(imagePath: imagePath!, heroTag: heroTag);
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

class FullScreenImageView extends StatefulWidget {
  final String imagePath;
  final String? heroTag;

  const FullScreenImageView({super.key, required this.imagePath, this.heroTag});

  @override
  State<FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<FullScreenImageView> {
  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.8,
                maxScale: 4.0,
                boundaryMargin: const EdgeInsets.all(20),
                panEnabled: true,
                scaleEnabled: true,
                child: Center(
                  child: widget.heroTag != null
                      ? Hero(
                          tag: widget.heroTag!,
                          child: Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.image_not_supported,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                        )
                      : Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.image_not_supported, color: Colors.white, size: 64),
                        ),
                ),
              ),
            ),

            Positioned(
              top: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints.tightFor(width: 48, height: 48),
                ),
              ),
            ),

            Positioned(
              bottom: 32,
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
                    'Tap to close • Pinch to zoom',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
