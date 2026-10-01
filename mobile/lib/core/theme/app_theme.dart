import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

abstract final class AppTheme {
  static ThemeData get light => _build();

  static ThemeData _build() {
    const bg   = AppColors.background;
    const surf = AppColors.surface;
    const card = AppColors.card;
    const textP = AppColors.textPrimary;
    const textS = AppColors.textSecondary;
    const textH = AppColors.textHint;
    const div  = AppColors.divider;

    final base = ThemeData.light(useMaterial3: true);

    final textTheme = GoogleFonts.outfitTextTheme(base.textTheme)
        .apply(bodyColor: textP, displayColor: textP)
        .copyWith(
          displayLarge:  GoogleFonts.sora(color: textP, fontWeight: FontWeight.w700),
          displayMedium: GoogleFonts.sora(color: textP, fontWeight: FontWeight.w700),
          headlineLarge: GoogleFonts.sora(color: textP, fontWeight: FontWeight.w700),
          headlineMedium:GoogleFonts.sora(color: textP, fontWeight: FontWeight.w600),
          titleLarge:    GoogleFonts.sora(color: textP, fontWeight: FontWeight.w600),
        );

    return base.copyWith(
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.accent,
        surface: surf,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textP,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.sora(
          color: textP, fontSize: 20, fontWeight: FontWeight.w600),
        iconTheme: const IconThemeData(color: textP),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, AppSizes.buttonHeightMd),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
          elevation: 0,
          textStyle: GoogleFonts.outfit(
              fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, AppSizes.buttonHeightMd),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: GoogleFonts.outfit(
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surf,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: AppSizes.md),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            borderSide: BorderSide(color: div, width: 1)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            borderSide: BorderSide(color: div, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            borderSide: const BorderSide(color: AppColors.error, width: 1)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
        hintStyle: GoogleFonts.outfit(
            color: textH, fontSize: 15, fontWeight: FontWeight.w400),
        labelStyle: GoogleFonts.outfit(color: textS, fontSize: 14),
        errorStyle: GoogleFonts.outfit(color: AppColors.error, fontSize: 12),
      ),

      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: DividerThemeData(color: div, thickness: 1, space: 1),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1A1A2E),
        contentTextStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        behavior: SnackBarBehavior.floating,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surf,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXl)),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        labelStyle: GoogleFonts.outfit(
            fontSize: 13, fontWeight: FontWeight.w500, color: textP),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusRound),
            side: BorderSide(color: div)),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: AppSizes.sm),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}
