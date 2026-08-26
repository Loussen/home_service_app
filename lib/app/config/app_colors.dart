import 'package:flutter/material.dart';

/// MySancho brand tokens — Don Quixote inspired, modern marketplace.
abstract final class AppColors {
  static const Color primary = Color(0xFFC24E2D);
  static const Color primaryDark = Color(0xFF9A3B22);
  static const Color secondary = Color(0xFF3D4F7C);
  static const Color gold = Color(0xFFD4A84B);

  /// Soft surfaces
  static const Color parchment = Color(0xFFF1EBE3);
  static const Color mist = Color(0xFFE8EEF6);
  static const Color sageSoft = Color(0xFFE7F0E8);

  /// Legacy aliases used across screens (mapped to new palette).
  static const Color peach = Color(0xFFF3E4DE);
  static const Color peachRow = Color(0xFFF7EDE8);
  static const Color sky = secondary;
  static const Color skySoft = mist;
  static const Color cream = parchment;
  static const Color lavender = mist;

  static const Color published = Color(0xFF5F9A6B);
  static const Color statusNew = Color(0xFF5B7FB5);
  static const Color ink = Color(0xFF1C1917);
  static const Color muted = Color(0xFF7A746C);
  static const Color divider = Color(0xFFE4DED6);
  static const Color canvas = Color(0xFFF7F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color badge = Color(0xFFC24E2D);
}
