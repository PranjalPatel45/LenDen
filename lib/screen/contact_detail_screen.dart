import 'dart:async';

import 'package:flutter/material.dart';
import 'package:to_do/data/expense_repository.dart';
import 'package:to_do/data/settings_repository.dart';
import 'package:to_do/model/expense_model.dart';
import 'package:to_do/screen/form_screen.dart';
import 'package:to_do/utils/contact_identity.dart';
import 'package:to_do/utils/transaction_type.dart';

import '../widget/expense_tile.dart';
import '../utils/app_colors.dart';
import '../utils/app_snackbar.dart';
import '../utils/app_design.dart';
import '../utils/app_motion.dart';
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
  final Set<int> _restoredExpenseKeys = <int>{};
  void _navigateAndAddExpense() async {
    final newExpense = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        builder: (context) => AddTodoScreen(
          prefillContactName: widget.contactName,
          prefillPhoneNumber: widget.phoneNumber,
          allowedTypes: TransactionType.contactTypes,
          title: 'Add Lent or Borrowed',
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

  void _navigateToEditExpense(Expense expense) {
    unawaited(
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditExpenseScreen(
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
        child: FloatingActionButton(
          onPressed: _navigateAndAddExpense,
          backgroundColor: AppColors.highlight,
          foregroundColor: AppColors.white,
          elevation: 3,
          highlightElevation: 1,
          tooltip: 'Add transaction',
          child: const Icon(Icons.add_rounded, size: 26),
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

              if (contactExpenses.isEmpty) {
                return ResponsiveContent(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: GlassEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Start a transaction',
                        message:
                            'Record what you lent or borrowed with ${widget.contactName}.',
                        action: SizedBox(
                          width: 160,
                          child: GlassButton(
                            onPressed: _navigateAndAddExpense,
                            child: const Text('Add transaction'),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final currencySymbol = widget.settingsRepository.currencySymbol;

              return ResponsiveContent(
                maxWidth: 760,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  itemCount: contactExpenses.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 5),
                        child: SectionLabel(
                          label:
                              '${contactExpenses.length} ${contactExpenses.length == 1 ? 'transaction' : 'transactions'}',
                          icon: Icons.history_rounded,
                        ),
                      );
                    }
                    final expense = contactExpenses[index - 1];

                    final dismissible = Dismissible(
                      key: Key(expense.key.toString()),
                      direction: DismissDirection.endToStart,
                      background: const SizedBox.shrink(),
                      onDismissed: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          await deleteExpenseWithUndo(
                            context: context,
                            expense: expense,
                            expenseRepository: widget.expenseRepository,
                            restoredKeys: _restoredExpenseKeys,
                            onStateChanged: () => setState(() {}),
                          );
                        }
                      },
                      secondaryBackground: Container(
                        color: AppColors.borrowColor,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerRight,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: GestureDetector(
                        onTap: () => _navigateToEditExpense(expense),
                        child: ExpenseTile(
                          expense: expense,
                          currencySymbol: currencySymbol,
                        ),
                      ),
                    );
                    if (_restoredExpenseKeys.contains(expense.key)) {
                      return RestoreMotion(
                        key: ValueKey(
                          'restored-contact-expense-${expense.key}',
                        ),
                        child: dismissible,
                      );
                    }
                    return EntranceMotion(
                      key: ValueKey('contact-expense-${expense.key}'),
                      order: index - 1,
                      child: dismissible,
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