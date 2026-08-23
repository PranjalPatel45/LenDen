import 'package:flutter/material.dart';

import 'app_design.dart';
import 'app_motion.dart';

/// Centralized, high-performance navigation motion system.
///
/// Designed to deliver a responsive (150-220ms), fluid 60 FPS experience
/// on all devices (including low-end Android hardware) while strictly
/// honoring reduced motion preferences.
abstract final class AppTransitions {
  /// Fast fade-through for full-screen context replacements (e.g. Splash -> Home/Lock).
  static Route<T> fadeThrough<T>({required Widget page}) {
    return PageRouteBuilder<T>(
      transitionDuration: AppMotion.quickRoute,
      reverseTransitionDuration: AppMotion.quickRoute,
      pageBuilder: (context, animation, secondaryAnimation) =>
          RepaintBoundary(child: page),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (prefersReducedMotion(context)) return child;
        final curve = CurvedAnimation(
          parent: animation,
          curve: AppMotion.routeCurve,
        );
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curve),
            child: child,
          ),
        );
      },
    );
  }

  /// Upward slide & fade for modal forms and action overlays (e.g. Add/Edit Expense, Forgot PIN).
  static Route<T> slideUp<T>({required Widget page}) {
    return PageRouteBuilder<T>(
      transitionDuration: AppMotion.modal,
      reverseTransitionDuration: AppMotion.quickRoute,
      pageBuilder: (context, animation, secondaryAnimation) =>
          RepaintBoundary(child: page),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (prefersReducedMotion(context)) return child;
        final curve = CurvedAnimation(
          parent: animation,
          curve: AppMotion.routeCurve,
        );
        final position = Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curve);
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: position,
            child: child,
          ),
        );
      },
    );
  }

  /// Horizontal slide & fade for hierarchical detail route pushes (e.g. Contact Detail, Settings sub-screens).
  static Route<T> slideRight<T>({required Widget page}) {
    return PageRouteBuilder<T>(
      transitionDuration: AppMotion.route,
      reverseTransitionDuration: AppMotion.quickRoute,
      pageBuilder: (context, animation, secondaryAnimation) =>
          RepaintBoundary(child: page),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (prefersReducedMotion(context)) return child;
        final curve = CurvedAnimation(
          parent: animation,
          curve: AppMotion.routeCurve,
        );
        final position = Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).animate(curve);
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: position,
            child: child,
          ),
        );
      },
    );
  }

  /// Lightweight cross-fade helper for tab switching on bottom navigation.
  static Widget tabSwitch({
    required Widget child,
    required int index,
  }) {
    return AnimatedSwitcher(
      duration: AppMotion.quick,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.988, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(index),
        child: RepaintBoundary(child: child),
      ),
    );
  }
}
