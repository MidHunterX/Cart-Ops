import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopping_assist/core/utils/image_picker_util.dart';
import 'package:shopping_assist/core/widgets/delete_loading_overlay.dart';
import 'package:shopping_assist/core/widgets/item_image_view.dart';

class ItemFormKeypad extends StatefulWidget {
  final bool isLoading;
  final String itemName;
  final String? imagePath;
  final XFile? pendingImage;
  final ValueChanged<XFile?> onImagePicked;
  final VoidCallback onImageRemoved;
  final String discountStr;
  final bool isTeleKeypad;
  final Function(String) onKeyPressed;
  final VoidCallback onNameTap;
  final VoidCallback onDiscountTap;
  final VoidCallback onSubmit;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const ItemFormKeypad({
    super.key,
    required this.isLoading,
    required this.itemName,
    required this.imagePath,
    required this.pendingImage,
    required this.onImagePicked,
    required this.onImageRemoved,
    required this.discountStr,
    required this.isTeleKeypad,
    required this.onKeyPressed,
    required this.onNameTap,
    required this.onDiscountTap,
    required this.onSubmit,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  State<ItemFormKeypad> createState() => _ItemFormKeypadState();
}

class _ItemFormKeypadState extends State<ItemFormKeypad> {
  bool _showDeleteOverlay = false;
  Key _overlayKey = UniqueKey();

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  void _triggerHeavyHaptic() {
    HapticFeedback.heavyImpact();
  }

  void _triggerSelectionHaptic() {
    HapticFeedback.selectionClick();
  }

  void _handlePick(ImageSource source) async {
    _triggerHaptic();
    final file = await ImagePickerUtil.pickImage(source);
    if (file != null) {
      if (mounted) setState(() => _showDeleteOverlay = false);
      widget.onImagePicked(file);
    }
  }

  void _handleImageTap() {
    if (_showDeleteOverlay) {
      _triggerHeavyHaptic(); // Destructive action
      setState(() => _showDeleteOverlay = false);
      widget.onImageRemoved();
    } else {
      _triggerHaptic();
      setState(() {
        _showDeleteOverlay = true;
        _overlayKey = UniqueKey(); // Reset the animation
      });
    }
  }

  Widget _buildActionBtn({
    String? text,
    IconData? icon,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    Color? backgroundColor,
    Color? foregroundColor,
    bool isDestructive = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed: () {
            isDestructive ? _triggerHeavyHaptic() : _triggerHaptic();
            onTap();
          },
          onLongPress: onLongPress != null
              ? () {
                  _triggerSelectionHaptic();
                  onLongPress();
                }
              : null,
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
          onPressed: () {
            _triggerHaptic();
            widget.onKeyPressed(text);
          },
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

    bool hasDiscount = widget.discountStr.isNotEmpty && widget.discountStr != '0';
    bool hasText = widget.itemName.isNotEmpty;
    bool hasImage = widget.imagePath != null || widget.pendingImage != null;

    Color mainActionBg = colorScheme.primary;
    Color mainActionFg = colorScheme.onPrimary;
    Color inputActiveBg = colorScheme.primaryContainer;
    Color inputActiveFg = colorScheme.onPrimaryContainer;
    Color functionalBg = colorScheme.secondaryContainer;
    Color functionalFg = colorScheme.onSecondaryContainer;
    Color inputInactiveBg = colorScheme.surfaceContainerHighest;
    Color inputInactiveFg = colorScheme.onSurfaceVariant;
    Color destructiveBg = colorScheme.errorContainer;
    Color destructiveFg = colorScheme.onErrorContainer;

    return Column(
      children: [
        Row(
          children: [
            _buildActionBtn(
              text: widget.isLoading ? 'Loading...' : (hasText ? widget.itemName : 'Name'),
              backgroundColor: hasText ? inputActiveBg : inputInactiveBg,
              foregroundColor: hasText ? inputActiveFg : inputInactiveFg,
              onTap: widget.isLoading ? () {} : widget.onNameTap,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: hasImage
                    ? GestureDetector(
                        onTap: _handleImageTap,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _handleImageTap,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: inputActiveBg,
                                foregroundColor: inputActiveFg,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.zero,
                                elevation: 0,
                              ),
                              child: SizedBox(
                                height: 56,
                                width: double.infinity,
                                child: ItemImageView(
                                  imagePath: widget.pendingImage?.path ?? widget.imagePath,
                                  width: double.infinity,
                                  height: double.infinity,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            if (_showDeleteOverlay)
                              Positioned.fill(
                                child: DeleteLoadingOverlay(
                                  key: _overlayKey,
                                  duration: const Duration(seconds: 3),
                                  onComplete: () {
                                    if (mounted) {
                                      setState(() => _showDeleteOverlay = false);
                                    }
                                  },
                                  child: const SizedBox.shrink(),
                                ),
                              ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 1, // 1 ratio for Gallery
                            child: ElevatedButton(
                              onPressed: () => _handlePick(ImageSource.gallery),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: inputInactiveBg,
                                foregroundColor: inputInactiveFg,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
                                ),
                                padding: EdgeInsets.zero,
                                elevation: 0,
                                minimumSize: Size.zero,
                              ),
                              child: const SizedBox(
                                height: 56,
                                child: Center(child: Icon(Icons.photo_library, size: 20)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 1), // Tiny separator
                          Expanded(
                            flex: 2, // 2 ratio for Camera
                            child: ElevatedButton(
                              onPressed: () => _handlePick(ImageSource.camera),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: inputInactiveBg,
                                foregroundColor: inputInactiveFg,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
                                ),
                                padding: EdgeInsets.zero,
                                elevation: 0,
                                minimumSize: Size.zero,
                              ),
                              child: const SizedBox(
                                height: 56,
                                child: Center(child: Icon(Icons.photo_camera, size: 24)),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            _buildActionBtn(
              text: hasDiscount ? 'Disc: ${widget.discountStr}%' : 'Discount',
              backgroundColor: hasDiscount ? inputActiveBg : inputInactiveBg,
              foregroundColor: hasDiscount ? inputActiveFg : inputInactiveFg,
              onTap: widget.onDiscountTap,
            ),
            _buildActionBtn(
              icon: Icons.keyboard_tab,
              backgroundColor: functionalBg,
              foregroundColor: functionalFg,
              onTap: () => widget.onKeyPressed('=>'),
            ),
          ],
        ),
        Row(
          children: [
            _buildNumBtn(context, widget.isTeleKeypad ? '1' : '7'),
            _buildNumBtn(context, widget.isTeleKeypad ? '2' : '8'),
            _buildNumBtn(context, widget.isTeleKeypad ? '3' : '9'),
            _buildActionBtn(
              icon: Icons.backspace_outlined,
              backgroundColor: functionalBg,
              foregroundColor: functionalFg,
              onTap: () => widget.onKeyPressed('<='),
              onLongPress: () => widget.onKeyPressed('C'),
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
              onTap: () => widget.onKeyPressed('C'),
              isDestructive: true,
            ),
          ],
        ),
        Row(
          children: [
            _buildNumBtn(context, widget.isTeleKeypad ? '7' : '1'),
            _buildNumBtn(context, widget.isTeleKeypad ? '8' : '2'),
            _buildNumBtn(context, widget.isTeleKeypad ? '9' : '3'),
            _buildActionBtn(
              text: '—',
              backgroundColor: functionalBg,
              foregroundColor: functionalFg,
              onTap: () => widget.onKeyPressed('-'),
            ),
          ],
        ),
        Row(
          children: [
            _buildNumBtn(context, '.99'),
            _buildNumBtn(context, '0'),
            _buildNumBtn(context, '.'),
            _buildActionBtn(
              text: 'OK',
              backgroundColor: mainActionBg,
              foregroundColor: mainActionFg,
              onTap: widget.onSubmit,
            ),
          ],
        ),
      ],
    );
  }
}
