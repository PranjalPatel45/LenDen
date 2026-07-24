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
  static const double input = 14;
  static const double card = 20;
  static const double sheet = 24;
  static const double pill = 999;
}

abstract final class AppSize {
  static const double fieldHeight = 56;
}

abstract final class AppMotion {
  static const Duration quick = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 280);
}

/// Lightweight branded background. It uses layered palette tints without a
/// full-screen blur, keeping scrolling and animation inexpensive.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, 0.34, 0.68, 1],
          colors: [
            AppColors.background,
            AppColors.primary.withValues(alpha: 0.10),
            AppColors.softPeach.withValues(alpha: 0.10),
            AppColors.background,
          ],
        ),
      ),
      child: child,
    );
  }
}

/// Keeps phone layouts unchanged while preventing forms and lists from
/// stretching excessively on tablets and landscape screens.
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
          Icon(icon, size: 18, color: AppColors.highlight),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.15,
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
    this.color = AppColors.highlight,
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
        borderRadius: BorderRadius.circular(11),
        color: color.withValues(alpha: 0.11),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: size),
    );
  }
}
