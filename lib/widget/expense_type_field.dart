import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_design.dart';
import '../utils/app_motion.dart';
import '../utils/transaction_type.dart';

/// Shared type selector featuring visual segmented pill buttons.
class ExpenseTypeField extends StatelessWidget {
  const ExpenseTypeField({
    super.key,
    required this.selectedType,
    required this.onChanged,
    this.fieldLabel = 'Transaction Type',
    this.types = const ['Income', 'Expense', 'Lent', 'Borrowed'],
    this.itemTextColor = AppColors.primaryText,
  });

  final String? selectedType;
  final String? fieldLabel;
  final ValueChanged<String?> onChanged;
  final List<String> types;
  final Color itemTextColor;

  Color _colorForType(String type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.lendColorDark;
      case TransactionType.expense:
        return AppColors.borrowColorDark;
      case TransactionType.lent:
        return AppColors.primary;
      case TransactionType.borrowed:
        return AppColors.borrowedColorDark;
      default:
        return AppColors.primary;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case TransactionType.income:
        return Icons.trending_up_rounded;
      case TransactionType.expense:
        return Icons.trending_down_rounded;
      case TransactionType.lent:
        return Icons.north_east_rounded;
      case TransactionType.borrowed:
        return Icons.south_west_rounded;
      default:
        return Icons.swap_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final segmentWidget = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryText.withValues(alpha: 0.10),
        ),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: types.map((type) {
          final isSelected = selectedType == type;
          final typeColor = _colorForType(type);
          final icon = _iconForType(type);

          return PressScale(
            pressedScale: 0.96,
            child: InkWell(
              onTap: () => onChanged(type),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: AppMotion.quick,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? typeColor.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(
                          color: typeColor.withValues(alpha: 0.35),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? typeColor : AppColors.secondaryText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color:
                            isSelected ? typeColor : AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
              ),
            ),
          ),
          segmentWidget,
        ],
      );
    }

    return segmentWidget;
  }
}
