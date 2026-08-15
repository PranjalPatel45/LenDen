import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// App color palette
class AppColors {
  static const Duration snackBarDuration = Duration(milliseconds: 1500);
  static const Duration deletionSnackBarDuration = Duration(seconds: 3);

  // Background (Off White)
  static const Color background = Color(0xFFF8F9FA);

  // Card / surface
  static const Color cardSurface = Color(0xFFFBFAFF);

  // Primary text - High contrast slate
  static const Color primaryText = Color(0xFF1E2024);

  // Secondary text - Muted slate grey
  static const Color secondaryText = Color(0xFF64748B);

  // Primary (Soft Lavender) - for secondary buttons, badges, charts
  static const Color primary = Color(0xFF9D7BFF);

  // Accent (Baby Pink) - for soft accents, illustrations
  static const Color accent = Color(0xFFF472B6);

  // Highlight / CTA (Powder Blue) - for primary buttons, active states
  static const Color highlight = Color(0xFF3B82F6);

  // Success - Soft Green - for success messages, confirmations
  static const Color success = Color(0xFF10B981);

  // Error - Soft Red - for error messages, warnings
  static const Color error = Color(0xFFEF4444);

  // Snackbar colors
  static const Color snackbarNeutral = Color(0xFF1E1B4B);
  static const Color snackbarSuccess = Color(0xFF065F46);
  static const Color snackbarError = Color(0xFF991B1B);

  // Additional colors from palette
  static const Color softPeach = Color(0xFFFED7AA);
  static const Color softLavender = Color(0xFFDDD6FE);

  // Standard
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Color(0xFF94A3B8);
  static const Color lightGrey = Color(0xFFF1F5F9);

  // Income (Green) - color for income/earnings
  static const Color lendColor = Color(0xFF10B981);
  static const Color lendColorLight = Color(0xFFECFDF5);
  static const Color lendColorDark = Color(0xFF047857);

  // Expense (Red) - color for expenses/outflows
  static const Color borrowColor = Color(0xFFF43F5E);
  static const Color borrowColorLight = Color(0xFFFFF1F2);
  static const Color borrowColorDark = Color(0xFFBE123C);

  // Borrowed (Amber/Orange) - color for borrowed money
  static const Color borrowedColor = Color(0xFFF59E0B);
  static const Color borrowedColorLight = Color(0xFFFFFBEB);
  static const Color borrowedColorDark = Color(0xFFB45309);

  /// Applies the theme to a MaterialApp
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.light(
      primary: highlight,
      secondary: accent,
      surface: cardSurface,
      error: error,
      onPrimary: white,
      onSecondary: primaryText,
      onSurface: primaryText,
      onError: white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background.withValues(alpha: 0.92),
      foregroundColor: primaryText,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: primaryText,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: highlight,
      foregroundColor: white,
      elevation: 4,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: white,
      selectedItemColor: highlight,
      unselectedItemColor: secondaryText,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    cardTheme: CardThemeData(
      color: cardSurface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: highlight,
        foregroundColor: white,
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: highlight),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: glassInputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primary.withValues(alpha: 0.20)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primary.withValues(alpha: 0.20)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: highlight, width: 1.8),
      ),
      labelStyle: const TextStyle(color: secondaryText),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: snackbarNeutral,
      contentTextStyle: TextStyle(color: white, fontWeight: FontWeight.w500),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      insetPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
    dividerTheme: DividerThemeData(
      color: primaryText.withValues(alpha: 0.08),
      thickness: 1,
      space: 1,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: glassSheet,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cardSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      iconColor: primaryText,
      textColor: primaryText,
      minTileHeight: 56,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? highlight.withValues(alpha: 0.46)
            : lightGrey,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? highlight : white,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: primaryText,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 1.18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: primaryText,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: primaryText,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: primaryText),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: secondaryText),
      labelLarge: TextStyle(
        fontSize: 13,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: primaryText,
      ),
    ),
  );

  // ---- Liquid Glass derived surfaces ----
  static const double _glassBorderAlpha = 0.28;

  // Subtle border color (derived from existing palette)
  static final Color glassBorder = primaryText.withValues(alpha: _glassBorderAlpha);

  // Glass surfaces optimized for high contrast & premium readability
  static final Color glassCard = white.withValues(alpha: 0.88);
  static final Color glassCardBorder = white.withValues(alpha: 0.90);
  static final Color glassSheet = white.withValues(alpha: 0.94);
  static final Color glassInputFill = white.withValues(alpha: 0.85);
  static final Color glassNav = white.withValues(alpha: 0.90);

  // Glass gradients
  static final Gradient glassShimmer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      white.withValues(alpha: 0.45),
      white.withValues(alpha: 0.15),
      background.withValues(alpha: 0.05),
    ],
  );
}
