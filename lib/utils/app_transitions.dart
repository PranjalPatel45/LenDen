import 'package:flutter/material.dart';

import 'app_design.dart';
import 'app_motion.dart';

/// Central navigation motion language for the application.
///
/// The app deliberately uses exactly two route patterns so every transition
/// feels like it belongs to the same product:
///
/// 1. **Hierarchical push / pop** — handled by [MaterialPageRoute] together
///    with the theme's [PageTransitionsTheme]. This keeps the platform-native
///    slide, the Android predictive-back gesture, and consistent durations
///    across every detail/form/settings screen without any custom code.
///
/// 2. **Context switches** (`pushReplacement`, e.g. Splash → Lock/Home and
///    Lock → Home) — a fast, opacity-only fade-through. This is the cheapest
///    full-screen transition available (a single compositing layer, no
///    scaling, no sliding surfaces) and preserves the user's spatial context
///    when the destination screen replaces the current one.
abstract final class AppTransitions {
  /// Fast fade-through for full-screen context changes.
  ///
  /// Honors the platform "disable animations" accessibility setting: when
  /// reduced motion is requested the child is shown immediately with no
  /// transition at all.
  static Route<T> fadeThrough<T>({required Widget page}) {
    return PageRouteBuilder<T>(
      transitionDuration: AppMotion.route,
      reverseTransitionDuration: AppMotion.route,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (prefersReducedMotion(context)) return child;
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: AppMotion.routeCurve,
          ),
          child: child,
        );
      },
    );
  }
}
