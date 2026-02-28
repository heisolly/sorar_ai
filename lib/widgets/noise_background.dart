import 'dart:math';
import 'package:flutter/material.dart';

class NoiseBackground extends StatefulWidget {
  final Widget child;
  final double opacity;
  final Color? colorOverlay;

  const NoiseBackground({
    super.key,
    required this.child,
    this.opacity = 0.03, // Subtle noise
    this.colorOverlay,
  });

  @override
  State<NoiseBackground> createState() => _NoiseBackgroundState();
}

class _NoiseBackgroundState extends State<NoiseBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Speed of noise shift
    )..repeat();
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
        // Base content
        widget.child,

        // Noise Overlay
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _NoisePainter(
                    opacity: widget.opacity,
                    offset: _controller.value,
                    color: widget.colorOverlay ?? Colors.black,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _NoisePainter extends CustomPainter {
  final double opacity;
  final double offset;
  final Color color;
  final Random _random = Random();

  _NoisePainter({
    required this.opacity,
    required this.offset,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // We'll draw noise dots. Drawing pixel by pixel is too slow.
    // Optimization: Draw a smaller noise pattern and tile or stretch it?
    // Or just draw fewer random rects.

    // For performance in Flutter Web/Mobile, drawing thousands of points per frame is heavy.
    // A better "Noise" effect often involves a static image or a shader.
    // Since we can't easily add assets or shaders right now without setup,
    // we will simulate noise by drawing a lot of tiny faint rects.
    // LIMITATION: This might be CPU intensive if too many.

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Create a "grainy" feel with fewer, larger speckles
    // to save performance while giving texture.
    const double grainSize = 1.5;
    final int density = (size.width * size.height * 0.005).toInt().clamp(
      100,
      3000,
    );

    for (int i = 0; i < density; i++) {
      final double x = _random.nextDouble() * size.width;
      final double y = _random.nextDouble() * size.height;

      // Shift slightly based on animation offset to create "alive" static
      final double shiftX = (x + (offset * 10)) % size.width;
      final double shiftY = (y + (offset * 10)) % size.height;

      canvas.drawRect(
        Rect.fromLTWH(shiftX, shiftY, grainSize, grainSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) {
    return oldDelegate.offset != offset;
  }
}
