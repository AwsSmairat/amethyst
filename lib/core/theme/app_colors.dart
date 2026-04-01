import 'package:flutter/material.dart';

@immutable
final class AppColors {
  const AppColors._();

  // Surfaces
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5FAFC);
  static const Color surfaceContainerLow = Color(0xFFEFF4F6);
  static const Color surfaceContainerHigh = Color(0xFFE4E9EB);
  static const Color surfaceContainerHighest = Color(0xFFDEE3E5);

  // Text
  static const Color primaryText = Color(0xFF0A2540);
  static const Color onSurface = Color(0xFF171C1E);
  static const Color onSurfaceVariant = Color(0xFF40484F);
  static const Color outlineVariant = Color(0xFFC0C7D0);

  // Brand
  static const Color primary = Color(0xFF005681);
  static const Color primaryContainer = Color(0xFF0B6FA4);
  static const Color secondary = Color(0xFF00658B);
  static const Color tertiary = Color(0xFF00596E);
  static const Color tertiaryFixed = Color(0xFFB6EAFF);
  static const Color tertiaryFixedDim = Color(0xFF6ED3F5);

  // Status
  static const Color success = Color(0xFF6BBF59);
  static const Color error = Color(0xFFBA1A1A);

  // Signature gradient: linear-gradient(135deg, #0B6FA4, #2FA4D9, #6ED3F5)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF0B6FA4),
      Color(0xFF2FA4D9),
      Color(0xFF6ED3F5),
    ],
  );
}

