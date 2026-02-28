import 'package:flutter/material.dart';
import 'package:parot_ai/theme/app_motion.dart';

class SoftExpansion extends StatefulWidget {
  final bool isExpanded;
  final Widget child;
  final Duration duration;

  const SoftExpansion({
    super.key,
    required this.isExpanded,
    required this.child,
    this.duration = AppMotion.kMedium, // 260-300ms
  });

  @override
  State<SoftExpansion> createState() => _SoftExpansionState();
}

class _SoftExpansionState extends State<SoftExpansion>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    // Animate height linearly for smooth expansion
    _heightFactor = _controller.drive(CurveTween(curve: AppMotion.emphasis));

    // Fade in slightly delayed or sync
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.2,
          1.0,
          curve: AppMotion.emphasis,
        ), // Slight delay on opacity
      ),
    );

    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(SoftExpansion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
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
        return ClipRect(
          child: Align(
            heightFactor: _heightFactor.value,
            alignment: Alignment.topCenter,
            child: Opacity(opacity: _opacity.value, child: widget.child),
          ),
        );
      },
      child: widget.child,
    );
  }
}
