import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/app_theme.dart';

class PremiumBackground extends StatelessWidget {
  final Widget child;

  const PremiumBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Background
        Container(color: AppColors.primaryBackground),

        // Subtle Gradient Orbs
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryBrand.withValues(alpha: 0.1),
                  AppColors.primaryBrand.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: -50,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.success.withValues(alpha: 0.05),
                  AppColors.success.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),

        // Noise/Texture Overlay (Local custom painter)
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.2, // Increased for custom painter to be visible
              child: CustomPaint(painter: _NoisePainter()),
            ),
          ),
        ),

        // Content
        child,
      ],
    );
  }
}

class _NoisePainter extends CustomPainter {
  final Random _random = Random();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Draw random tiny dots to simulate grain
    for (int i = 0; i < 2000; i++) {
      final double x = _random.nextDouble() * size.width;
      final double y = _random.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
