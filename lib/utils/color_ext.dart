import 'package:flutter/material.dart';

extension ColorExt on Color {
  /// Use Color.fromRGBO to avoid precision loss from deprecated withOpacity
  Color withOpacitySafe(double opacity) {
    final argb = toARGB32();
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    return Color.fromRGBO(r, g, b, opacity);
  }
}
