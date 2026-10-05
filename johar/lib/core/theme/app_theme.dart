import 'package:flutter/material.dart';
import 'app_colors.dart';

/// One type family (Noto) for script coverage: Latin, Devanagari and Ol Chiki
/// share weight and x-height. Sizes are above Material defaults because many
/// users are first-time smartphone readers. Rounded, soft surfaces throughout.
abstract final class AppTheme {
  static const _fallback = ['NotoSansDevanagari', 'NotoSansOlChiki'];

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.manganese,
      onPrimary: Colors.white,
      primaryContainer: AppColors.manganeseSoft,
      onPrimaryContainer: AppColors.manganese,
      secondary: AppColors.safeGreen,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.manganeseSoft,
      onSecondaryContainer: AppColors.manganese,
      error: AppColors.fireRed,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.coal,
      onSurfaceVariant: AppColors.slate,
      outline: AppColors.line,
      outlineVariant: AppColors.line,
    );

    const text = TextTheme(
      displaySmall: TextStyle(fontSize: 34, height: 1.15, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontSize: 28, height: 1.2, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      headlineSmall: TextStyle(fontSize: 24, height: 1.3, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(fontSize: 21, height: 1.3, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 18, height: 1.35, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 18, height: 1.5),
      bodyMedium: TextStyle(fontSize: 16, height: 1.5),
      labelLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'NotoSans',
      fontFamilyFallback: _fallback,
      scaffoldBackgroundColor: AppColors.mineral,
      textTheme: text.apply(bodyColor: AppColors.coal, displayColor: AppColors.coal),
      splashFactory: InkSparkle.splashFactory,
    );

    RoundedRectangleBorder rounded(double r) => RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.mineral,
        foregroundColor: AppColors.coal,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'NotoSans',
          fontFamilyFallback: _fallback,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.coal,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: rounded(AppRadii.lg),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 58), // big, glove-friendly target
          shape: rounded(AppRadii.md),
          textStyle: text.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 58),
          shape: rounded(AppRadii.md),
          side: const BorderSide(color: AppColors.manganese, width: 1.5),
          foregroundColor: AppColors.manganese,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: rounded(AppRadii.sm), textStyle: text.labelLarge),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(shape: rounded(AppRadii.sm)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.manganese, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.fireRed, width: 1.5),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: rounded(AppRadii.sm),
        side: const BorderSide(color: AppColors.line),
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.coal),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        selectedColor: AppColors.manganeseSoft,
        backgroundColor: AppColors.surface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.manganeseSoft,
        indicatorShape: rounded(AppRadii.md),
        height: 70,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
      ),
      dialogTheme: DialogThemeData(backgroundColor: AppColors.surface, shape: rounded(AppRadii.lg)),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: rounded(AppRadii.md),
        backgroundColor: AppColors.coal,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.manganese,
        linearTrackColor: AppColors.line,
      ),
      listTileTheme: ListTileThemeData(shape: rounded(AppRadii.md)),
    );
  }
}
