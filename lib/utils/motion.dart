import 'package:flutter/material.dart';

class AppMotion {
  // Durations
  static const Duration durationShort = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 250);
  static const Duration durationLong = Duration(milliseconds: 400);

  // Curves
  static const Curve curveStandard = Curves.easeOutCubic;
  static const Curve curveDecelerate = Curves.easeOutQuart;
  static const Curve curveEmphasized = Curves.easeOutQuint;
  static const Curve curveBounce = Curves.easeOutBack; // Use sparingly

  /// Helper for staggered grid/list animations
  static Duration stagger(int index) => Duration(milliseconds: index * 50);
}
