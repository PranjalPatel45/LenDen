import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double input = 16;
  static const double card = 20;
  static const double sheet = 28;
  static const double pill = 999;
}

abstract final class AppSize {
  static const double fieldHeight = 56;
}

abstract final class AppMotion {
  static const Duration quick = Duration(milliseconds: 120);
  static const Duration quickRoute = Duration(milliseconds: 150);
  static const Duration route = Duration(milliseconds: 180);
  static const Duration modal = Duration(milliseconds: 190);
  static const Duration standard = Duration(milliseconds: 220);

  /// Easing shared by full-screen route transitions.
  static const Curve routeCurve = Curves.easeOutCubic;
}

/// Lightweight branded background with soft multi-point color tints.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.45, 1.0],
          colors: [
            AppColors.background,
            Color(0xFFEFF6FF), // Soft Powder Tint
            AppColors.background,
          ],
        ),
      ),
      child: child,
    );
  }
}

/// Prevents forms and lists from stretching excessively on tablet/desktop widths.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 720,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                fontSize: 11,
              ),
        ),
      ],
    );
  }
}

class GlassIcon extends StatelessWidget {
  const GlassIcon({
    super.key,
    required this.icon,
    this.color = AppColors.primary,
    this.size = 20,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: size),
    );
  }
}
