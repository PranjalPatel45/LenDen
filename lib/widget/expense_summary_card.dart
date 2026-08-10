import 'package:flutter/material.dart';
import 'package:to_do/utils/currency_helper.dart';
import 'package:to_do/widget/glass_widgets.dart';
import '../utils/app_colors.dart';
import '../utils/app_design.dart';
import '../utils/app_motion.dart';

class ExpenseSummaryCard extends StatelessWidget {
  final double totalBalance;
  final double netLending;
  final double totalIncome;
  final double totalExpense;
  final double totalLent;
  final double totalBorrowed;
  final String currencySymbol;
  final String periodLabel;

  const ExpenseSummaryCard({
    super.key,
    required this.totalBalance,
    this.netLending = 0,
    this.totalIncome = 0,
    this.totalExpense = 0,
    required this.totalLent,
    required this.totalBorrowed,
    this.currencySymbol = '\$',
    this.periodLabel = 'This Month',
  });

  @override
  Widget build(BuildContext context) {
    final heading = periodLabel == 'This Month'
        ? "THIS MONTH'S AVAILABLE BALANCE"
        : '${periodLabel.toUpperCase()} AVAILABLE BALANCE';

    return RepaintBoundary(
      child: EntranceMotion(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: GlassCard(
          radius: 20,
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 18,
                      color: AppColors.highlight,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        heading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primaryText.withValues(alpha: 0.64),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: '$periodLabel balance',
                  value: formatCurrency(totalBalance, currencySymbol),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      totalBalance < 0
                          ? '-${formatCurrency(totalBalance.abs(), currencySymbol)}'
                          : formatCurrency(totalBalance, currencySymbol),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 36,
                        color: totalBalance > 0
                            ? AppColors.lendColorDark
                            : totalBalance < 0
                            ? AppColors.borrowColorDark
                            : AppColors.grey,
                      ),
                    ),
                  ),
                ),
                if (totalBalance < 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Your outflow is higher than your inflow',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.borrowColorDark.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (totalBalance > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Income and borrowed cash minus expenses and lent money',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.lendColorDark.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 22),
                Divider(color: AppColors.primaryText.withValues(alpha: 0.08)),
                const SizedBox(height: 16),
                Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            context,
                            'Income',
                            totalIncome,
                            AppColors.lendColorDark,
                            Icons.trending_up_rounded,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildSummaryItem(
                            context,
                            'Expense',
                            totalExpense,
                            AppColors.borrowColorDark,
                            Icons.trending_down_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            context,
                            'Lent',
                            totalLent,
                            AppColors.highlight,
                            Icons.north_east_rounded,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildSummaryItem(
                            context,
                            'Borrowed',
                            totalBorrowed,
                            AppColors.borrowedColor,
                            Icons.south_west_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.44),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.glassCardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people_alt_outlined,
                        size: 17,
                        color: AppColors.highlight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Net lending',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(
                            formatCurrency(netLending.abs(), currencySymbol),
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: netLending >= 0
                                  ? AppColors.highlight
                                  : AppColors.borrowedColorDark,
                              fontWeight: FontWeight.w800,
                            ),
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
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 10.5,
                    color: AppColors.primaryText.withValues(alpha: 0.62),
                    letterSpacing: 0.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatCurrency(amount, currencySymbol),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
