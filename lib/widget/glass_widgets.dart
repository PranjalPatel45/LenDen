import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_colors.dart';
import '../utils/app_design.dart';
import '../utils/app_motion.dart';

/// Premium iOS-inspired Liquid Glass surface.
///
/// Notes:
/// - Uses BackdropFilter blur for the frosted/glass effect.
/// - Uses ONLY colors derived from AppColors palette (with alpha).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? glassColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool enabled;
  final AlignmentGeometry? alignment;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 24,
    this.glassColor,
    this.borderColor,
    this.onTap,
    this.enabled = true,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveGlass = glassColor ?? AppColors.glassCard;
    final Color effectiveBorder = borderColor ?? AppColors.glassCardBorder;

    final Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryText.withValues(alpha: 0.075),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: Container(
            alignment: alignment,
            decoration: BoxDecoration(
              color: effectiveGlass,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: effectiveBorder, width: 1),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        gradient: AppColors.glassShimmer,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return PressScale(
        enabled: enabled,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: enabled ? onTap : null,
            child: surface,
          ),
        ),
      );
    }

    return surface;
  }
}

class GlassInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const GlassInput({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return FocusMotion(
      builder: (context, focused, duration) => AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        width: double.infinity,
        height: AppSize.fieldHeight,
        decoration: BoxDecoration(
          color: AppColors.glassInputFill,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(
            color: focused
                ? AppColors.highlight.withValues(alpha: 0.72)
                : AppColors.glassCardBorder,
            width: focused ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: focused
                  ? AppColors.highlight.withValues(alpha: 0.14)
                  : AppColors.primary.withValues(alpha: 0.07),
              blurRadius: focused ? 16 : 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: AppColors.black, fontSize: 16),
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            labelStyle: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 14,
            ),
            hintStyle: TextStyle(
              color: AppColors.black.withValues(alpha: 0.35),
            ),
            prefixIcon: prefixIcon != null
                ? SizedBox(
                    width: 40,
                    height: 48,
                    child: Center(child: prefixIcon),
                  )
                : null,
            suffixIcon: suffixIcon != null
                ? SizedBox(
                    width: 40,
                    height: 48,
                    child: Center(child: suffixIcon),
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double radius;
  final Color? color;
  final Color? foregroundColor;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.radius = 16,
    this.color,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      enabled: onPressed != null,
      pressedScale: 0.975,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: color ?? AppColors.highlight,
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: color == null || color == AppColors.highlight
                          ? AppColors.highlight
                          : AppColors.glassCardBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryText.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: foregroundColor ?? AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassEmptyState extends StatelessWidget {
  const GlassEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return EntranceMotion(
      child: GlassCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: AppColors.highlight.withValues(alpha: 0.11),
                border: Border.all(
                  color: AppColors.highlight.withValues(alpha: 0.16),
                ),
              ),
              child: Icon(icon, size: 28, color: AppColors.highlight),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryText.withValues(alpha: 0.64),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class GlassLoadingState extends StatelessWidget {
  const GlassLoadingState({super.key, this.label = 'Loading…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: label,
      child: LoadingPulse(
        child: SizedBox(
          width: 240,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              ...List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primaryText.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FractionallySizedBox(
                              widthFactor: index == 1 ? 0.72 : 0.88,
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryText.withValues(
                                    alpha: 0.09,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FractionallySizedBox(
                              widthFactor: 0.56,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryText.withValues(
                                    alpha: 0.055,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
