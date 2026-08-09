import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_design.dart';
import '../utils/app_motion.dart';

/// Shared type selector used by both transaction forms.
class ExpenseTypeField extends StatelessWidget {
  const ExpenseTypeField({
    super.key,
    required this.selectedType,
    required this.onChanged,
    this.fieldLabel = 'Transaction Type',
    this.types = const ['Lent', 'Borrowed'],
    this.itemTextColor = AppColors.primaryText,
  });

  final String? selectedType;
  final String? fieldLabel;
  final ValueChanged<String?> onChanged;
  final List<String> types;
  final Color itemTextColor;

  @override
  Widget build(BuildContext context) {
    final fieldWidget = FocusMotion(
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
        child: LayoutBuilder(
          builder: (context, constraints) => DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedType,
              isExpanded: true,
              menuWidth: constraints.maxWidth,
              itemHeight: AppSize.fieldHeight,
              borderRadius: BorderRadius.circular(AppRadius.input),
              dropdownColor: AppColors.cardSurface,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.secondaryText,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              hint: const _SelectedTypeContent(label: 'Select type'),
              selectedItemBuilder: (context) => types
                  .map((label) => _SelectedTypeContent(label: label))
                  .toList(growable: false),
              items: types
                  .map(
                    (label) => DropdownMenuItem(
                      value: label,
                      child: Text(
                        label,
                        style: TextStyle(fontSize: 16, color: itemTextColor),
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );

    if (fieldLabel != null && fieldLabel!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Text(
              fieldLabel!,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          fieldWidget,
        ],
      );
    }

    return fieldWidget;
  }
}

class _SelectedTypeContent extends StatelessWidget {
  const _SelectedTypeContent({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.swap_horiz_rounded,
          size: 22,
          color: AppColors.primaryText,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: label == 'Type' ? 14 : 16,
            color: AppColors.primaryText,
          ),
        ),
      ],
    );
  }
}
