import 'package:flutter/material.dart';
import 'package:parot_ai/theme/app_motion.dart';

class PremiumPageTransitionBuilder extends PageTransitionsBuilder {
  const PremiumPageTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Only animate the incoming route
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: AppMotion.emphasis,
    );

    return FadeTransition(
      opacity: curvedAnimation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.985, end: 1.0).animate(curvedAnimation),
        child: child,
      ),
    );
  }
}
