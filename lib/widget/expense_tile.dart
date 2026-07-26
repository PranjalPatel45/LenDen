import 'package:flutter/material.dart';
import 'package:to_do/model/expense_model.dart';
import 'package:to_do/utils/currency_helper.dart';
import 'package:to_do/utils/transaction_type.dart';
import '../utils/app_colors.dart';
import '../utils/app_design.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final String currencySymbol;

  const ExpenseTile({
    super.key,
    required this.expense,
    this.currencySymbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = _colorForType(expense.type);
    final icon = _iconForType(expense.type);
    final isPositive = TransactionType.isPositive(expense.type);
    final signedAmount =
        '${isPositive ? '+' : '-'}${formatCurrency(expense.amount, currencySymbol)}';

    return Semantics(
      button: true,
      label:
          '${expense.type}, ${expense.contactName ?? expense.title}, $signedAmount, ${formatDate(expense.date)}',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.white.withValues(alpha: 0.88),
          border: Border.all(
            color: AppColors.primaryText.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryText.withValues(alpha: 0.045),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 3,
              child: ColoredBox(color: tileColor.withValues(alpha: 0.85)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 13, 16, 13),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      color: tileColor.withValues(alpha: 0.12),
                    ),
                    child: Icon(icon, size: 18, color: tileColor),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.contactName ?? expense.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: AppColors.grey,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                formatDate(expense.date),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontSize: 12,
                                      color: AppColors.primaryText.withValues(
                                        alpha: 0.58,
                                      ),
                                    ),
                              ),
                            ),
                          ],
                        ),
                        if (expense.reason != null &&
                            expense.reason!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            expense.reason!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: 12,
                                  color: AppColors.primaryText.withValues(
                                    alpha: 0.52,
                                  ),
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Flexible(
                    flex: 1,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerEnd,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            signedAmount,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _darkColorForType(expense.type),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            expense.type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.65,
                              color: tileColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForType(String type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.lendColor;
      case TransactionType.expense:
        return AppColors.borrowColor;
      case TransactionType.lent:
        return AppColors.highlight;
      case TransactionType.borrowed:
        return AppColors.borrowedColor;
      default:
        return AppColors.grey;
    }
  }

  Color _darkColorForType(String type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.lendColorDark;
      case TransactionType.expense:
        return AppColors.borrowColorDark;
      case TransactionType.lent:
        return AppColors.highlight;
      case TransactionType.borrowed:
        return AppColors.borrowedColorDark;
      default:
        return AppColors.primaryText;
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
        return Icons.receipt_long_rounded;
    }
  }
}
