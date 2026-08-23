import 'package:flutter/material.dart';
import 'package:to_do/utils/currency_helper.dart';
import 'package:to_do/widget/glass_widgets.dart';
import '../utils/app_colors.dart';
import '../utils/app_design.dart';
import '../utils/app_motion.dart';

/// Centerpiece Light Liquid-Glass Financial Summary Dashboard Header
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
        ? "AVAILABLE BALANCE"
        : "${periodLabel.toUpperCase()} BALANCE";

    return RepaintBoundary(
      child: EntranceMotion(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: GlassCard(
            radius: 26,
            glassColor: AppColors.white.withValues(alpha: 0.90),
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        heading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondaryText,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: totalBalance >= 0
                            ? AppColors.lendColorLight
                            : AppColors.borrowColorLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: totalBalance >= 0
                              ? AppColors.lendColorDark.withValues(alpha: 0.2)
                              : AppColors.borrowColorDark.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        totalBalance >= 0 ? 'Healthy' : 'Deficit',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: totalBalance >= 0
                              ? AppColors.lendColorDark
                              : AppColors.borrowColorDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Hero Available Balance Display
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
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.4,
                                color: totalBalance > 0
                                    ? AppColors.lendColorDark
                                    : totalBalance < 0
                                        ? AppColors.borrowColorDark
                                        : AppColors.primaryText,
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Divider(color: AppColors.primaryText.withValues(alpha: 0.08)),
                const SizedBox(height: 16),

                // Primary Split: MONEY LENT vs MONEY BORROWED
                Row(
                  children: [
                    Expanded(
                      child: _buildSplitCard(
                        context: context,
                        title: 'MONEY LENT',
                        subtitle: 'Owed to you',
                        amount: totalLent,
                        color: AppColors.lendColorDark,
                        bgTint: AppColors.lendColorLight,
                        borderColor:
                            AppColors.lendColorDark.withValues(alpha: 0.15),
                        icon: Icons.north_east_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSplitCard(
                        context: context,
                        title: 'MONEY BORROWED',
                        subtitle: 'You owe',
                        amount: totalBorrowed,
                        color: AppColors.borrowedColorDark,
                        bgTint: AppColors.borrowedColorLight,
                        borderColor: AppColors.borrowedColorDark
                            .withValues(alpha: 0.15),
                        icon: Icons.south_west_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Secondary Split: Cash Flow (Income vs Expense)
                Row(
                  children: [
                    Expanded(
                      child: _buildCashFlowRow(
                        title: 'Income',
                        amount: totalIncome,
                        color: AppColors.lendColorDark,
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCashFlowRow(
                        title: 'Expense',
                        amount: totalExpense,
                        color: AppColors.borrowColorDark,
                        icon: Icons.trending_down_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Net Lending Ledger Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryText.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Net Contact Ledger Balance',
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
                            '${netLending >= 0 ? '+' : '-'}${formatCurrency(netLending.abs(), currencySymbol)}',
                            style: TextStyle(
                              fontSize: 15,
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

  Widget _buildSplitCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required double amount,
    required Color color,
    required Color bgTint,
    required Color borderColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatCurrency(amount, currencySymbol),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowRow({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryText.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryText,
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              formatCurrency(amount, currencySymbol),
              style: TextStyle(
                fontSize: 13.5,
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
