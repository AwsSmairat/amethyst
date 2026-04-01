import 'package:amethyst/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
final class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryContainer,
        brightness: Brightness.light,
        surface: AppColors.surface,
      ).copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        error: AppColors.error,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        outlineVariant: AppColors.outlineVariant,
      ),
      scaffoldBackgroundColor: AppColors.surface,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: AppColors.surface.withValues(alpha: 0.8),
        foregroundColor: AppColors.primaryText,
        centerTitle: false,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: AppColors.surfaceLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    final TextTheme t = GoogleFonts.cairoTextTheme(base);
    return t.copyWith(
      displayLarge: t.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.primaryText,
      ),
      headlineSmall: t.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.primaryText,
      ),
      titleLarge: t.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primaryText,
      ),
      titleMedium: t.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primaryText,
      ),
      bodyLarge: t.bodyLarge?.copyWith(color: AppColors.onSurface),
      bodyMedium: t.bodyMedium?.copyWith(color: AppColors.onSurface),
      labelLarge: t.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
      labelMedium: t.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
      labelSmall: t.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }
}

