import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_colors.dart';
import '../utils/app_design.dart';
import '../utils/app_motion.dart';

/// Premium Light Liquid-Glass Surface.
///
/// Features:
/// - Translucent base surface
/// - Controlled backdrop blur (sigmaX: 12, sigmaY: 12)
/// - Specular highlight border
/// - Ambient depth shadow
/// - 100% text contrast and daylight legibility
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
    this.radius = 20,
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
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.primaryText.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            alignment: alignment,
            decoration: BoxDecoration(
              color: effectiveGlass,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: effectiveBorder, width: 1.2),
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
                  padding: padding ?? const EdgeInsets.all(18),
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
  final String? fieldLabel;
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
    this.fieldLabel,
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
    final effectiveLabel = fieldLabel;
    final effectiveHint = hintText;

    final inputWidget = FocusMotion(
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
                ? AppColors.primary
                : AppColors.primaryText.withValues(alpha: 0.12),
            width: focused ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: focused
                  ? AppColors.primary.withValues(alpha: 0.14)
                  : AppColors.primaryText.withValues(alpha: 0.03),
              blurRadius: focused ? 14 : 8,
              offset: const Offset(0, 4),
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
          style: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: effectiveHint,
            floatingLabelBehavior: FloatingLabelBehavior.never,
            hintStyle: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: prefixIcon != null
                ? SizedBox(
                    width: 44,
                    height: AppSize.fieldHeight,
                    child: Center(child: prefixIcon),
                  )
                : null,
            suffixIcon: suffixIcon != null
                ? SizedBox(
                    width: 44,
                    height: AppSize.fieldHeight,
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
              vertical: 16,
            ),
          ),
        ),
      ),
    );

    if (effectiveLabel != null && effectiveLabel.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Text(
              effectiveLabel,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
              ),
            ),
          ),
          inputWidget,
        ],
      );
    }

    return inputWidget;
  }
}

class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double radius;
  final Color? color;
  final Color? foregroundColor;
  final bool isLoading;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.radius = 16,
    this.color,
    this.foregroundColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    return PressScale(
      enabled: effectiveOnPressed != null,
      pressedScale: 0.975,
      child: Semantics(
        button: true,
        enabled: effectiveOnPressed != null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: effectiveOnPressed,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 50),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: color ?? AppColors.primary,
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: color == null || color == AppColors.primary
                          ? AppColors.primary
                          : AppColors.glassCardBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (color ?? AppColors.primary)
                            .withValues(alpha: 0.24),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: foregroundColor ?? AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                    child: isLoading
                        ? SizedBox(
                            height: 20,
                            child: Center(
                              child: SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: foregroundColor ?? AppColors.white,
                                ),
                              ),
                            ),
                          )
                        : child,
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
        radius: 24,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.primary.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(icon, size: 30, color: AppColors.primary),
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
                    color: AppColors.secondaryText,
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
                      fontWeight: FontWeight.w700,
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
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryText.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
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
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryText.withValues(
                                    alpha: 0.09,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FractionallySizedBox(
                              widthFactor: 0.56,
                              child: Container(
                                height: 9,
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
