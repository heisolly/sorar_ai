import 'package:flutter/material.dart';

class AppMotion {
  // Durations
  static const Duration kInstant = Duration(milliseconds: 120);
  static const Duration kFast = Duration(milliseconds: 180);
  static const Duration kMedium = Duration(milliseconds: 260);
  static const Duration kSlow = Duration(milliseconds: 340);

  // Curves
  static const Curve emphasis = Curves.easeOutCubic;
  static const Curve standard = Curves.easeInOutCubic;

  // Specific Motion Spec Durations
  static const Duration pageTransition = Duration(milliseconds: 260); // 260ms
  static const Duration cardFadeUi = Duration(milliseconds: 260); // 260ms
  static const Duration buttonScale = Duration(milliseconds: 120); // 120-150ms
  static const Duration expansion = Duration(milliseconds: 300); // 260-300ms
  static const Duration ambientLoop = Duration(seconds: 3); // 2-3s
}
