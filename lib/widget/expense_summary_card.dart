import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_design.dart';
import '../utils/app_motion.dart';
import '../utils/currency_helper.dart';
import 'glass_widgets.dart';

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
            radius: 24,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 18,
                      color: AppColors.highlight,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        heading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryText,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
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
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: totalBalance > 0
                                ? AppColors.lendColorDark
                                : totalBalance < 0
                                ? AppColors.borrowColorDark
                                : AppColors.primaryText,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
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
                            AppColors.lendColorLight,
                            Icons.trending_up_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryItem(
                            context,
                            'Expense',
                            totalExpense,
                            AppColors.borrowColorDark,
                            AppColors.borrowColorLight,
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
                            AppColors.highlight.withValues(alpha: 0.10),
                            Icons.north_east_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryItem(
                            context,
                            'Borrowed',
                            totalBorrowed,
                            AppColors.borrowedColorDark,
                            AppColors.borrowedColorLight,
                            Icons.south_west_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassCardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people_alt_rounded,
                        size: 18,
                        color: AppColors.highlight,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Net Lending Ledger',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(
                            formatCurrency(netLending.abs(), currencySymbol),
                            style: TextStyle(
                              fontSize: 14,
                              color: netLending >= 0
                                  ? AppColors.lendColorDark
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
    Color bgTint,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius: BorderRadius.circular(14),
      ),
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
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: color.withValues(alpha: 0.88),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatCurrency(amount, currencySymbol),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
