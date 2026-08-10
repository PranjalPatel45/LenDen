import 'dart:async';

import 'package:flutter/material.dart';
import 'package:to_do/data/expense_repository.dart';
import 'package:to_do/data/settings_repository.dart';
import 'package:to_do/model/expense_model.dart';
import 'package:to_do/screen/form_screen.dart';
import 'package:to_do/utils/contact_identity.dart';
import 'package:to_do/utils/currency_helper.dart';
import 'package:to_do/utils/transaction_type.dart';

import '../widget/expense_tile.dart';
import '../utils/app_colors.dart';
import '../utils/app_snackbar.dart';
import '../utils/app_design.dart';
import '../utils/app_motion.dart';
import '../utils/app_transitions.dart';
import '../utils/delete_restore.dart';
import '../widget/glass_widgets.dart';
import 'edit_expense_screen.dart';

class ContactDetailScreen extends StatefulWidget {
  final String contactName;
  final String? phoneNumber;

  const ContactDetailScreen({
    super.key,
    required this.contactName,
    this.phoneNumber,
    this.expenseRepository = const ExpenseRepository(),
    this.settingsRepository = const SettingsRepository(),
  });

  final ExpenseRepository expenseRepository;
  final SettingsRepository settingsRepository;

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  final Set<dynamic> _restoredExpenseKeys = <dynamic>{};

  void _navigateAndAddExpense() async {
    final newExpense = await Navigator.push<Expense>(
      context,
      AppTransitions.slideUp<Expense>(
        page: AddTodoScreen(
          prefillContactName: widget.contactName,
          prefillPhoneNumber: widget.phoneNumber,
          allowedTypes: TransactionType.contactTypes,
          title: 'Lend or Borrow with ${widget.contactName}',
          settingsRepository: widget.settingsRepository,
        ),
      ),
    );

    if (newExpense != null) {
      try {
        await widget.expenseRepository.add(newExpense);
      } catch (e) {
        if (mounted) {
          AppSnackbar.showError(
            context: context,
            message: 'Failed to save transaction.',
          );
        }
      }
    }
  }

  void _settleBalance(double netBalance, String currencySymbol) async {
    if (netBalance == 0) return;

    final settleType =
        netBalance > 0 ? TransactionType.borrowed : TransactionType.lent;
    final settleAmount = netBalance.abs();
    final now = DateTime.now().toIso8601String().split('T')[0];

    final settlementExpense = Expense(
      title: widget.contactName,
      amount: settleAmount,
      date: now,
      type: settleType,
      contactName: widget.contactName,
      phoneNumber: widget.phoneNumber,
      reason: 'Settled balance with ${widget.contactName}',
    );

    try {
      await widget.expenseRepository.add(settlementExpense);
      if (mounted) {
        AppSnackbar.showSuccess(
          context: context,
          message: 'Balance settled with ${widget.contactName}',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context: context,
          message: 'Failed to settle balance.',
        );
      }
    }
  }

  void _navigateToEditExpense(Expense expense) {
    unawaited(
      Navigator.push(
        context,
        AppTransitions.slideUp(
          page: EditExpenseScreen(
            expense: expense,
            expenseRepository: widget.expenseRepository,
            settingsRepository: widget.settingsRepository,
          ),
        ),
      ),
    );
  }

  List<Expense> _getContactExpenses(List<Expense> allExpenses) {
    return allExpenses
        .where((expense) {
          if (!TransactionType.isContactType(expense.type)) return false;
          return isExpenseForContact(
            expensePhoneNumber: expense.phoneNumber,
            contactPhoneNumber: widget.phoneNumber,
            expenseContactName: expense.contactName,
            contactName: widget.contactName,
          );
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.contactName)),
      floatingActionButton: PressScale(
        pressedScale: 0.94,
        hoverScale: 1.025,
        child: FloatingActionButton.extended(
          onPressed: _navigateAndAddExpense,
          backgroundColor: AppColors.highlight,
          foregroundColor: AppColors.white,
          elevation: 3,
          highlightElevation: 1,
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text(
            'Lend / Borrow',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      body: AppBackground(
        child: ListenableBuilder(
          listenable: widget.settingsRepository.listenable,
          builder: (context, _) => ValueListenableBuilder(
            valueListenable: widget.expenseRepository.listenable,
            builder: (context, box, _) {
              final allExpenses = widget.expenseRepository.getAll();
              final contactExpenses = _getContactExpenses(allExpenses);
              final currencySymbol = widget.settingsRepository.currencySymbol;

              double totalLent = 0;
              double totalBorrowed = 0;
              for (final e in contactExpenses) {
                if (e.type == TransactionType.lent) {
                  totalLent += e.amount;
                } else if (e.type == TransactionType.borrowed) {
                  totalBorrowed += e.amount;
                }
              }
              final netBalance = totalLent - totalBorrowed;

              String dynamicStatus;
              Color statusColor;
              if (netBalance > 0) {
                dynamicStatus =
                    '${widget.contactName} owes you ${formatCurrency(netBalance, currencySymbol)}';
                statusColor = AppColors.lendColorDark;
              } else if (netBalance < 0) {
                dynamicStatus =
                    'You owe ${widget.contactName} ${formatCurrency(netBalance.abs(), currencySymbol)}';
                statusColor = AppColors.borrowedColorDark;
              } else {
                dynamicStatus = 'All settled up with ${widget.contactName}';
                statusColor = AppColors.grey;
              }

              return ResponsiveContent(
                maxWidth: 760,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 12, bottom: 88),
                  itemCount: contactExpenses.isEmpty
                      ? 1
                      : contactExpenses.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: GlassCard(
                          radius: 20,
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Hero(
                                    tag: 'contact-avatar-${widget.contactName}',
                                    child: CircleAvatar(
                                      backgroundColor: AppColors.highlight
                                          .withValues(alpha: 0.12),
                                      child: Text(
                                        widget.contactName.isNotEmpty
                                            ? widget.contactName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.highlight,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.contactName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        if (widget.phoneNumber != null &&
                                            widget.phoneNumber!.isNotEmpty)
                                          Text(
                                            widget.phoneNumber!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.primaryText
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (netBalance != 0)
                                    TextButton.icon(
                                      onPressed: () => _settleBalance(
                                        netBalance,
                                        currencySymbol,
                                      ),
                                      icon: const Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Settle',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.highlight,
                                        backgroundColor: AppColors.highlight
                                            .withValues(alpha: 0.1),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  dynamicStatus,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          'Lent',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primaryText
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          formatCurrency(
                                            totalLent,
                                            currencySymbol,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.lendColorDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 30,
                                    width: 1,
                                    color: AppColors.primaryText.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          'Borrowed',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primaryText
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          formatCurrency(
                                            totalBorrowed,
                                            currencySymbol,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.borrowedColorDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (contactExpenses.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: GlassEmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No transactions',
                          message:
                              'Tap "Lend / Borrow" below to add a transaction with ${widget.contactName}.',
                        ),
                      );
                    }

                    final expense = contactExpenses[index - 1];
                    final swipeTile = TransactionSwipeTile(
                      key: ValueKey('contact-swipe-expense-${expense.key}'),
                      expense: expense,
                      currencySymbol: currencySymbol,
                      onEdit: () => _navigateToEditExpense(expense),
                      onDelete: () => deleteExpenseWithUndo(
                        // The list item context can unmount during deletion;
                        // keep the stable screen context for the Undo overlay.
                        context: this.context,
                        expense: expense,
                        expenseRepository: widget.expenseRepository,
                        restoredKeys: _restoredExpenseKeys,
                        onStateChanged: () => setState(() {}),
                      ),
                    );

                    if (_restoredExpenseKeys.contains(expense.key)) {
                      return RestoreMotion(
                        key: ValueKey(
                          'restored-contact-expense-${expense.key}',
                        ),
                        child: swipeTile,
                      );
                    }

                    return EntranceMotion(
                      key: ValueKey('contact-expense-${expense.key}'),
                      order: index - 1,
                      child: swipeTile,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
