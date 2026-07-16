import 'package:flutter/material.dart';

class DeleteLoadingOverlay extends StatefulWidget {
  final Duration duration;
  final VoidCallback onComplete;
  final Widget child;

  const DeleteLoadingOverlay({
    super.key,
    required this.duration,
    required this.onComplete,
    required this.child,
  });

  @override
  State<DeleteLoadingOverlay> createState() => _DeleteLoadingOverlayState();
}

class _DeleteLoadingOverlayState extends State<DeleteLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)..forward();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final barWidth = constraints.maxWidth * _animation.value;
                    return Stack(
                      children: [
                        // Dark overlay background
                        Container(color: Colors.black.withValues(alpha: 0.6)),
                        // Translucent growing fill bar – now using constraints.maxWidth
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: barWidth,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.red.withValues(alpha: 0.5),
                                  Colors.red.withValues(alpha: 0.7),
                                  Colors.red.withValues(alpha: 1.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Icon in center on top of everything
                        const Center(
                          child: Icon(Icons.delete_outline, color: Colors.white, size: 40),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
