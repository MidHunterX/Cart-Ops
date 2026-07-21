import 'package:flutter/material.dart';

class UnitQuantitySelector extends StatefulWidget {
  final TextEditingController? controller;
  final String? quantity;
  final FocusNode? focusNode;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const UnitQuantitySelector({
    super.key,
    this.controller,
    this.quantity,
    this.focusNode,
    this.isActive = false,
    this.onTap,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  State<UnitQuantitySelector> createState() => _UnitQuantitySelectorState();
}

class _UnitQuantitySelectorState extends State<UnitQuantitySelector> {
  TextEditingController? _localController;

  TextEditingController get _effectiveController {
    if (widget.controller != null) return widget.controller!;
    _localController ??= TextEditingController(text: widget.quantity);
    return _localController!;
  }

  @override
  void didUpdateWidget(covariant UnitQuantitySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null) {
      if (_localController == null) {
        _localController = TextEditingController(text: widget.quantity);
      } else if (widget.quantity != oldWidget.quantity) {
        _localController!.text = widget.quantity ?? '';
      }
    }
  }

  @override
  void dispose() {
    _localController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: widget.isActive ? colorScheme.primaryContainer : null,
          border: Border.all(
            color: widget.isActive ? colorScheme.primary : colorScheme.outline,
            width: widget.isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _buildButton(context, Icons.remove, widget.onDecrement, isLeft: true),
            Expanded(
              child: TextFormField(
                controller: _effectiveController,
                focusNode: widget.focusNode,
                readOnly: true,
                showCursor: true,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onTap: widget.onTap,
              ),
            ),
            _buildButton(context, Icons.add, widget.onIncrement, isLeft: false),
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
      ),
    );
  }
}
