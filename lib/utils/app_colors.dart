import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// LenDen Light Liquid-Glass Color System
class AppColors {
  static const Duration snackBarDuration = Duration(milliseconds: 1500);
  static const Duration deletionSnackBarDuration = Duration(seconds: 3);

  // Clean Off-White Base Background
  static const Color background = Color(0xFFF8FAFC);

  // Pure White Card Surface
  static const Color cardSurface = Color(0xFFFFFFFF);

  // High-Contrast Slate Typography (Maximum Daylight Contrast)
  static const Color primaryText = Color(0xFF0F172A); // Slate 900
  static const Color secondaryText = Color(0xFF475569); // Slate 600
  static const Color mutedText = Color(0xFF94A3B8); // Slate 400

  // Primary Brand Accents
  static const Color primary = Color(0xFF2563EB); // Power Blue
  static const Color highlight = Color(0xFF3B82F6); // Powder Blue
  static const Color accent = Color(0xFFF472B6); // Baby Pink

  // Soft Pastel Accents
  static const Color softBlue = Color(0xFF93C5FD);
  static const Color softLavender = Color(0xFFEEF2FF);
  static const Color softPeach = Color(0xFFFED7AA);
  static const Color softMint = Color(0xFFD1FAE5);

  // Status & Utility Colors
  static const Color success = Color(0xFF059669);
  static const Color error = Color(0xFFE11D48);

  // Snackbar Surfaces
  static const Color snackbarNeutral = Color(0xFF0F172A);
  static const Color snackbarSuccess = Color(0xFF065F46);
  static const Color snackbarError = Color(0xFF991B1B);

  // Standard Neutrals
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Color(0xFF94A3B8);
  static const Color lightGrey = Color(0xFFF1F5F9);

  // Income / Money Lent (Green / Emerald)
  static const Color lendColor = Color(0xFF059669);
  static const Color lendColorLight = Color(0xFFECFDF5);
  static const Color lendColorDark = Color(0xFF047857);

  // Expense / Money Borrowed (Rose / Coral)
  static const Color borrowColor = Color(0xFFE11D48);
  static const Color borrowColorLight = Color(0xFFFFF1F2);
  static const Color borrowColorDark = Color(0xFFBE123C);

  // Active Borrowed Debt (Amber)
  static const Color borrowedColor = Color(0xFFD97706);
  static const Color borrowedColorLight = Color(0xFFFFFBEB);
  static const Color borrowedColorDark = Color(0xFFB45309);

  /// Material 3 Light Theme Definition
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: accent,
          surface: cardSurface,
          error: error,
          onPrimary: white,
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
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 6,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: white,
          selectedItemColor: primary,
          unselectedItemColor: secondaryText,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        cardTheme: CardThemeData(
          color: cardSurface,
          elevation: 2,
          shadowColor: primaryText.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: primaryText.withValues(alpha: 0.06),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: white,
            minimumSize: const Size(48, 52),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: glassInputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: primaryText.withValues(alpha: 0.10),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: primaryText.withValues(alpha: 0.10),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primary, width: 2.0),
          ),
          labelStyle: const TextStyle(color: secondaryText),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: snackbarNeutral,
          contentTextStyle: TextStyle(
            color: white,
            fontWeight: FontWeight.w600,
          ),
          elevation: 6,
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
          elevation: 12,
          showDragHandle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: cardSurface,
          surfaceTintColor: Colors.transparent,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
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
                ? primary.withValues(alpha: 0.46)
                : lightGrey,
          ),
          thumbColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? primary : white,
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
            fontSize: 36,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.4,
            color: primaryText,
          ),
          headlineMedium: TextStyle(
            fontSize: 26,
            height: 1.18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
            color: primaryText,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            height: 1.25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: primaryText,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: primaryText,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w500,
            color: primaryText,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w500,
            color: secondaryText,
          ),
          labelLarge: TextStyle(
            fontSize: 13,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: primaryText,
          ),
        ),
      );

  // ---- Light Liquid-Glass Derived Surfaces ----
  static const double _glassBorderAlpha = 0.22;

  static final Color glassBorder =
      primaryText.withValues(alpha: _glassBorderAlpha);

  // Liquid glass surfaces (translucent tint for depth layers)
  static final Color glassCard = white.withValues(alpha: 0.88);
  static final Color glassCardBorder = white.withValues(alpha: 0.95);
  static final Color glassSheet = white.withValues(alpha: 0.95);
  static final Color glassInputFill = white.withValues(alpha: 0.90);
  static final Color glassNav = white.withValues(alpha: 0.92);

  // Specular reflection gradient
  static final Gradient glassShimmer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      white.withValues(alpha: 0.60),
      white.withValues(alpha: 0.20),
      softBlue.withValues(alpha: 0.08),
    ],
  );
}
