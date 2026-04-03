import 'package:flutter/material.dart';

/// Centralized shop-inspired palette (water blue, cyan, mint, navy).
/// RTL-friendly; use with [AppTheme.light].
///
/// [primaryContainer] stays the legacy teal used by [LoginPage] only — do not
/// reuse for post-login primary actions; prefer [brandPrimary].
@immutable
final class AppColors {
  const AppColors._();

  // —— Brand (spec) ——
  static const Color brandPrimary = Color(0xFF2F80ED);
  static const Color softSkyBlue = Color(0xFF56CCF2);
  static const Color deepNavy = Color(0xFF0F2747);
  static const Color aquaCyan = Color(0xFF4FC3F7);
  static const Color freshMint = Color(0xFF7ED957);
  static const Color lightMint = Color(0xFFB8F5C8);
  static const Color softBackground = Color(0xFFF5F9FC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color softGreyText = Color(0xFF6B7280);
  static const Color darkText = Color(0xFF1F2937);

  // —— Surfaces ——
  static const Color surfaceLowest = cardWhite;
  static const Color surface = softBackground;
  static const Color surfaceContainerLow = Color(0xFFE8F2FA);
  static const Color surfaceContainerHigh = Color(0xFFDDE8F2);
  static const Color surfaceContainerHighest = Color(0xFFD0DCE8);

  // —— Text ——
  static const Color primaryText = darkText;
  static const Color onSurface = Color(0xFF111827);
  static const Color onSurfaceVariant = softGreyText;
  static const Color outlineVariant = Color(0xFFD1D5DB);

  // —— Theme / Material mapping ——
  static const Color primary = brandPrimary;
  static const Color primaryContainer = Color(0xFF0B6FA4);
  static const Color secondary = deepNavy;
  static const Color tertiary = aquaCyan;
  static const Color tertiaryFixed = Color(0xFFB8E8FF);
  static const Color tertiaryFixedDim = softSkyBlue;

  // —— Status ——
  static const Color success = freshMint;
  static const Color error = Color(0xFFDC2626);

  // —— Gradients ——
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[brandPrimary, softSkyBlue],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[deepNavy, brandPrimary],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[freshMint, softSkyBlue],
  );

  /// Very subtle screen backdrop (optional).
  static const LinearGradient scaffoldSoftGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFFEEF6FC), softBackground],
  );

  // —— Shadows ——
  static List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(
      color: deepNavy.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: brandPrimary.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
