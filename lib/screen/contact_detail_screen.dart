import 'dart:async';

import 'package:flutter/material.dart';
import '../data/expense_repository.dart';
import '../data/settings_repository.dart';
import '../model/expense_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_design.dart';
import '../utils/app_motion.dart';
import '../utils/app_snackbar.dart';
import '../utils/app_transitions.dart';
import '../utils/contact_identity.dart';
import '../utils/currency_helper.dart';
import '../utils/delete_restore.dart';
import '../utils/transaction_type.dart';
import '../widget/expense_tile.dart';
import '../widget/glass_widgets.dart';
import 'edit_expense_screen.dart';
import 'form_screen.dart';

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

  void _navigateAndAddExpense({String? defaultType}) async {
    final newExpense = await Navigator.push<Expense>(
      context,
      AppTransitions.slideUp<Expense>(
        page: AddTodoScreen(
          prefillContactName: widget.contactName,
          prefillPhoneNumber: widget.phoneNumber,
          allowedTypes: defaultType != null
              ? [defaultType]
              : TransactionType.contactTypes,
          title: defaultType == TransactionType.lent
              ? 'Lend to ${widget.contactName}'
              : defaultType == TransactionType.borrowed
                  ? 'Borrow from ${widget.contactName}'
                  : 'Lend or Borrow with ${widget.contactName}',
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
          onPressed: () => _navigateAndAddExpense(),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text(
            'Lend / Borrow',
            style: TextStyle(fontWeight: FontWeight.w800),
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
                statusColor = AppColors.secondaryText;
              }

              return ResponsiveContent(
                maxWidth: 760,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 12, bottom: 92),
                  itemCount: contactExpenses.isEmpty
                      ? 1
                      : contactExpenses.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: GlassCard(
                          radius: 24,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Hero(
                                    tag: 'contact-avatar-${widget.contactName}',
                                    child: CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColors.softLavender,
                                      child: Text(
                                        widget.contactName.isNotEmpty
                                            ? widget.contactName[0]
                                                .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.contactName,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primaryText,
                                          ),
                                        ),
                                        if (widget.phoneNumber != null &&
                                            widget.phoneNumber!.isNotEmpty)
                                          Text(
                                            widget.phoneNumber!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.secondaryText,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (netBalance != 0)
                                    ElevatedButton.icon(
                                      onPressed: () => _settleBalance(
                                        netBalance,
                                        currencySymbol,
                                      ),
                                      icon: const Icon(
                                        Icons.check_circle_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('Settle Up'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: AppColors.white,
                                        minimumSize: Size.zero,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  dynamicStatus,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _navigateAndAddExpense(
                                        defaultType: TransactionType.lent,
                                      ),
                                      icon: const Icon(
                                        Icons.north_east_rounded,
                                        size: 16,
                                        color: AppColors.lendColorDark,
                                      ),
                                      label: const Text('Lend Money'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.lendColorDark,
                                        side: BorderSide(
                                          color: AppColors.lendColorDark
                                              .withValues(alpha: 0.3),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _navigateAndAddExpense(
                                        defaultType: TransactionType.borrowed,
                                      ),
                                      icon: const Icon(
                                        Icons.south_west_rounded,
                                        size: 16,
                                        color: AppColors.borrowedColorDark,
                                      ),
                                      label: const Text('Borrow Money'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            AppColors.borrowedColorDark,
                                        side: BorderSide(
                                          color: AppColors.borrowedColorDark
                                              .withValues(alpha: 0.3),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
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
                          title: 'No transactions yet',
                          message:
                              'Tap "+ Lend" or "- Borrow" above to record money with ${widget.contactName}.',
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
