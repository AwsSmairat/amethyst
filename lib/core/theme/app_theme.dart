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
    final headline = GoogleFonts.manropeTextTheme(base);
    final body = GoogleFonts.interTextTheme(base);

    return body.copyWith(
      displayLarge: headline.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.primaryText,
      ),
      headlineSmall: headline.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.primaryText,
      ),
      titleLarge: headline.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primaryText,
      ),
      titleMedium: headline.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primaryText,
      ),
      bodyLarge: body.bodyLarge?.copyWith(color: AppColors.onSurface),
      bodyMedium: body.bodyMedium?.copyWith(color: AppColors.onSurface),
      labelLarge: body.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
      labelMedium: body.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
      labelSmall: body.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }
}

