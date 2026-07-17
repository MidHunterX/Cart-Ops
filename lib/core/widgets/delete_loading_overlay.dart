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
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: widget.duration, vsync: this);
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.3).animate(_controller);

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.9, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _controller.forward();
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
                  animation: _controller,
                  builder: (context, child) {
                    final barWidth = constraints.maxWidth * _progressAnimation.value;
                    final opacity = _fadeAnimation.value;

                    return Opacity(
                      opacity: opacity,
                      child: Stack(
                        children: [
                          // Dark overlay background
                          Container(color: Colors.black.withValues(alpha: 0.6 * opacity)),
                          // Translucent growing fill bar
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
                                    Colors.red.withValues(alpha: 0.5 * opacity),
                                    Colors.red.withValues(alpha: 0.7 * opacity),
                                    Colors.red.withValues(alpha: 1.0 * opacity),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Icon in center on top of everything
                          Center(
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.white.withValues(alpha: opacity),
                              size: 40,
                            ),
                          ),
                        ],
                      ),
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
