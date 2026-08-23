import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_design.dart';
import '../utils/app_motion.dart';

/// Floating Light Liquid-Glass Navigation Bar
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.space_dashboard_rounded, 'Dashboard'),
    (Icons.people_alt_rounded, 'Connect'),
    (Icons.tune_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.primaryText.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.glassNav,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.95),
                  width: 1.2,
                ),
              ),
              child: SizedBox(
                height: 66,
                child: Row(
                  children: List.generate(
                    _items.length,
                    (index) => Expanded(child: _buildItem(context, index)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final (icon, label) = _items[index];
    final selected = currentIndex == index;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: PressScale(
          pressedScale: 0.95,
          child: InkWell(
            onTap: () => onTap(index),
            borderRadius: BorderRadius.circular(22),
            splashColor: AppColors.primary.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: AnimatedContainer(
                duration: motionDuration(
                  context,
                  AppMotion.standard,
                ),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: selected
                      ? Border.all(
                          color: AppColors.primary.withValues(alpha: 0.18),
                        )
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color:
                          selected ? AppColors.primary : AppColors.secondaryText,
                    ),
                    const SizedBox(height: 3),
                    AnimatedDefaultTextStyle(
                      duration: motionDuration(
                        context,
                        AppMotion.quick,
                      ),
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        color:
                            selected ? AppColors.primary : AppColors.secondaryText,
                        letterSpacing: 0.1,
                      ),
                      child: Text(label),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
