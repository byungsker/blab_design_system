import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';
import 'blab_token_theme.dart';

class BLabTheme {
  BLabTheme._();

  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: BLabColors.primary,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: BLabColors.scaffoldLight,
    textTheme: _textTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BLabColors.grey100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BLabRadius.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BLabRadius.md),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BLabRadius.md),
        borderSide: const BorderSide(color: BLabColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BLabRadius.md),
        borderSide: const BorderSide(color: BLabColors.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BLabColors.primary,
        foregroundColor: BLabTokenTheme.light.actionPrimaryForeground,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BLabRadius.md),
        ),
        elevation: 0,
        textStyle: BLabTypography.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: BLabColors.primary,
        textStyle: BLabTypography.label,
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: BLabColors.primary,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: BLabColors.scaffoldDark,
    textTheme: _textTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BLabColors.elevatedDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BLabRadius.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BLabRadius.md),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BLabRadius.md),
        borderSide: const BorderSide(color: BLabColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BLabRadius.md),
        borderSide: const BorderSide(color: BLabColors.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BLabColors.primary,
        foregroundColor: BLabTokenTheme.dark.actionPrimaryForeground,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BLabRadius.md),
        ),
        elevation: 0,
        textStyle: BLabTypography.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: BLabColors.primary,
        textStyle: BLabTypography.label,
      ),
    ),
  );

  /// Maps BLab typography tokens to Material [TextTheme] slots.
  static const TextTheme _textTheme = TextTheme(
    displayLarge: BLabTypography.display,
    displayMedium: BLabTypography.display,
    displaySmall: BLabTypography.h1,
    headlineLarge: BLabTypography.h1,
    headlineMedium: BLabTypography.h2,
    headlineSmall: BLabTypography.h2,
    titleLarge: BLabTypography.title,
    titleMedium: BLabTypography.subtitle,
    titleSmall: BLabTypography.subtitle,
    bodyLarge: BLabTypography.body,
    bodyMedium: BLabTypography.body,
    bodySmall: BLabTypography.caption,
    labelLarge: BLabTypography.label,
    labelMedium: BLabTypography.label,
    labelSmall: BLabTypography.tab,
  );
}
