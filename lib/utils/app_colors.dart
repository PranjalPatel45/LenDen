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

  // Primary text
  static const Color primaryText = Color(0xFF2A2D32);

  // Secondary text
  static const Color secondaryText = Color(0xFF000000);

  // Primary (Soft Lavender) - for secondary buttons, badges, charts
  static const Color primary = Color(0xFFCDB4FF);

  // Accent (Baby Pink) - for soft accents, illustrations
  static const Color accent = Color(0xFFF8BBD0);

  // Highlight / CTA (Powder Blue) - for primary buttons, active states
  static const Color highlight = Color(0xFF7EB6FF);

  // Success - Soft Green - for success messages, confirmations
  static const Color success = Color(0xFFA8E6CF);

  // Error - Soft Red - for error messages, warnings
  static const Color error = Color(0xFFFFB4B4);

  // Snackbar colors
  static const Color snackbarNeutral = Color(0xFF3600A3);
  static const Color snackbarSuccess = Color(0xFF0B843D);
  static const Color snackbarError = Color(0xFFE22412);

  // Additional colors from palette
  static const Color softPeach = Color(0xFFFFE5B4);
  static const Color softLavender = Color(0xFFCDB4FF);

  // Standard
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Color(0xFF9CA3AF);
  static const Color lightGrey = Color(0xFFE5E7EB);

  // Income (Green) - color for income/earnings
  static const Color lendColor = Color(0xFFA8E6CF);
  static const Color lendColorLight = Color(0xFFE8F8EF);
  static const Color lendColorDark = Color(0xFF2E7D32);

  // Expense (Red) - color for expenses/outflows
  static const Color borrowColor = Color(0xFFFFB4B4);
  static const Color borrowColorLight = Color(0xFFFFEAEA);
  static const Color borrowColorDark = Color(0xFFC62828);

  // Borrowed (Amber/Orange) - color for borrowed money
  static const Color borrowedColor = Color(0xFFE67E22);
  static const Color borrowedColorLight = Color(0xFFFFF3E0);
  static const Color borrowedColorDark = Color(0xFFC05C0F);

  /// Applies the theme to a MaterialApp
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.light(
      primary: highlight,
      secondary: accent,
      surface: cardSurface,
      error: error,
      onPrimary: primaryText,
      onSecondary: primaryText,
      onSurface: primaryText,
      onError: white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background.withValues(alpha: 0.94),
      foregroundColor: primaryText,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: primaryText,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: highlight,
      foregroundColor: white,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: highlight,
        foregroundColor: primaryText,
        minimumSize: const Size(48, 50),
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
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary.withValues(alpha: 0.22)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary.withValues(alpha: 0.22)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: highlight, width: 1.6),
      ),
      labelStyle: TextStyle(color: secondaryText.withValues(alpha: 0.8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: snackbarNeutral,
      contentTextStyle: const TextStyle(color: white),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      insetPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
    dividerTheme: DividerThemeData(
      color: primary.withValues(alpha: 0.14),
      thickness: 1,
      space: 1,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: glassSheet,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cardSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            : lightGrey.withValues(alpha: 0.8),
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
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
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
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: primaryText),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: primaryText),
      labelLarge: TextStyle(
        fontSize: 13,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
    ),
  );

  // ---- Liquid Glass derived surfaces ----
  static const double _glassAlpha = 0.14;
  static const double _glassBorderAlpha = 0.26;

  // Off-white frosted glass base
  static final Color glassLight = background.withValues(alpha: _glassAlpha);

  // Subtle border color (derived from existing palette)
  static final Color glassBorder = primary.withValues(alpha: _glassBorderAlpha);

  // Glass surfaces
  static final Color glassCard = background.withValues(alpha: 0.72);
  static final Color glassCardBorder = primary.withValues(alpha: 0.28);
  static final Color glassSheet = background.withValues(alpha: 0.82);
  static final Color glassInputFill = white.withValues(alpha: 0.55);
  static final Color glassNav = white.withValues(alpha: 0.72);

  // Glass gradients
  static final Gradient glassShimmer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      white.withValues(alpha: 0.28),
      white.withValues(alpha: 0.06),
      background.withValues(alpha: 0.02),
    ],
  );

  static final Gradient glassHighlight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      highlight.withValues(alpha: 0.16),
      highlight.withValues(alpha: 0.03),
    ],
  );
}
