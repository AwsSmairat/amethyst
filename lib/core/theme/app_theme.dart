import 'package:amethyst/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
final class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.light(
      primary: AppColors.brandPrimary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.softSkyBlue.withValues(alpha: 0.35),
      onPrimaryContainer: AppColors.deepNavy,
      secondary: AppColors.deepNavy,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.surfaceContainerLow,
      onSecondaryContainer: AppColors.deepNavy,
      tertiary: AppColors.aquaCyan,
      onTertiary: AppColors.deepNavy,
      tertiaryContainer: AppColors.lightMint.withValues(alpha: 0.45),
      onTertiaryContainer: AppColors.deepNavy,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outlineVariant,
      outlineVariant: AppColors.outlineVariant,
      shadow: AppColors.deepNavy.withValues(alpha: 0.12),
      scrim: Colors.black54,
      inverseSurface: AppColors.deepNavy,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.softSkyBlue,
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: AppColors.surface.withValues(alpha: 0.92),
        foregroundColor: AppColors.deepNavy,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.deepNavy),
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.deepNavy,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: AppColors.deepNavy.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppColors.brandPrimary,
          disabledForegroundColor: Colors.white70,
          disabledBackgroundColor: AppColors.softGreyText.withValues(
            alpha: 0.35,
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandPrimary,
          side: const BorderSide(color: AppColors.brandPrimary, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.brandPrimary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightMint.withValues(alpha: 0.35),
        selectedColor: AppColors.freshMint.withValues(alpha: 0.45),
        disabledColor: AppColors.surfaceContainerHigh,
        labelStyle: GoogleFonts.cairo(
          color: AppColors.deepNavy,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        secondaryLabelStyle: GoogleFonts.cairo(
          color: AppColors.softGreyText,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cardWhite,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.softSkyBlue.withValues(alpha: 0.45),
        labelTextStyle: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          final bool selected = s.contains(WidgetState.selected);
          return GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? AppColors.deepNavy : AppColors.softGreyText,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          final bool selected = s.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.brandPrimary : AppColors.softGreyText,
            size: 24,
          );
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.deepNavy,
        unselectedLabelColor: AppColors.softGreyText,
        indicatorColor: AppColors.brandPrimary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.cairo(
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.cairo(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.cardWhite,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.deepNavy,
        contentTextStyle: GoogleFonts.cairo(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.brandPrimary,
        textColor: AppColors.darkText,
        selectedColor: AppColors.brandPrimary,
        selectedTileColor: AppColors.softSkyBlue.withValues(alpha: 0.15),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: GoogleFonts.cairo(color: AppColors.softGreyText),
        floatingLabelStyle: GoogleFonts.cairo(color: AppColors.brandPrimary),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandPrimary,
        circularTrackColor: Color(0x1A2F80ED),
      ),
      iconTheme: const IconThemeData(color: AppColors.deepNavy),
      primaryIconTheme: const IconThemeData(color: AppColors.deepNavy),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    final TextTheme t = GoogleFonts.cairoTextTheme(base);
    return t.copyWith(
      displayLarge: t.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.deepNavy,
      ),
      headlineSmall: t.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.deepNavy,
      ),
      titleLarge: t.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.deepNavy,
      ),
      titleMedium: t.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.deepNavy,
      ),
      bodyLarge: t.bodyLarge?.copyWith(color: AppColors.onSurface),
      bodyMedium: t.bodyMedium?.copyWith(color: AppColors.onSurface),
      bodySmall: t.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
      labelLarge: t.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: AppColors.deepNavy,
      ),
      labelMedium: t.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
      labelSmall: t.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.softGreyText,
      ),
    );
  }
}
