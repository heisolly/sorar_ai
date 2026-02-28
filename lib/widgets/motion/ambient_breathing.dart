import 'package:flutter/material.dart';
import 'package:parot_ai/theme/app_motion.dart';

class AmbientBreathing extends StatefulWidget {
  final Widget child;

  const AmbientBreathing({super.key, required this.child});

  @override
  State<AmbientBreathing> createState() => _AmbientBreathingState();
}

class _AmbientBreathingState extends State<AmbientBreathing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppMotion.ambientLoop,
      vsync: this,
    )..repeat(reverse: true);

    _opacity = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.standard));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(opacity: _opacity.value, child: widget.child);
      },
      child: widget.child,
    );
  }
}
