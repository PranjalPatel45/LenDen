import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_design.dart';
import '../utils/app_motion.dart';

/// A restrained floating navigation surface. The glass is concentrated here
/// because navigation benefits from remaining visually separate from content.
class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.people_rounded, 'Connect'),
    (Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryText.withValues(alpha: 0.09),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.glassNav,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.78),
                ),
              ),
              child: SizedBox(
                height: 64,
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
          pressedScale: 0.96,
          child: InkWell(
            onTap: () => onTap(index),
            borderRadius: BorderRadius.circular(18),
            splashColor: AppColors.highlight.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: AnimatedContainer(
                duration: motionDuration(
                  context,
                  AppMotion.standard,
                ),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.highlight.withValues(alpha: 0.11)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: selected
                          ? AppColors.highlight
                          : AppColors.secondaryText,
                    ),
                    const SizedBox(height: 3),
                    AnimatedDefaultTextStyle(
                      duration: motionDuration(
                        context,
                        AppMotion.quick,
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        height: 1,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? AppColors.highlight
                            : AppColors.secondaryText,
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
