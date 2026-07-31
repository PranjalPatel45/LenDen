import 'dart:async';

import 'package:flutter/material.dart';
import 'package:to_do/data/expense_repository.dart';
import 'package:to_do/data/settings_repository.dart';
import 'package:to_do/model/expense_model.dart';
import 'package:to_do/widget/app_nav_bar.dart';
import 'package:to_do/widget/glass_widgets.dart';

import '../widget/expense_summary_card.dart';
import '../widget/expense_tile.dart';
import '../utils/app_colors.dart';
import '../utils/app_snackbar.dart';
import '../utils/app_design.dart';
import '../utils/expense_period.dart';
import '../utils/app_motion.dart';
import '../utils/delete_restore.dart';
import '../utils/transaction_type.dart';
import '../utils/glass_toast.dart';
import 'form_screen.dart';
import 'edit_expense_screen.dart';
import 'connect_screen.dart';
import 'contact_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.expenseRepository = const ExpenseRepository(),
    this.settingsRepository = const SettingsRepository(),
  });

  final ExpenseRepository expenseRepository;
  final SettingsRepository settingsRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _contactSearchController =
      TextEditingController();
  final Set<int> _restoredExpenseKeys = <int>{};
  int _selectedIndex = 0;
  String _selectedPeriod = allExpensePeriods;
  DateTime? _lastBackPressTime;

  @override
  void dispose() {
    _contactSearchController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning ☀️';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon 🌤️';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening 🌅';
    } else {
      return 'Good Night 🌙';
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

  void _navigateAndAddCashFlow() async {
    final newExpense = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        builder: (context) => AddTodoScreen(
          allowedTypes: TransactionType.cashFlowTypes,
          title: 'Add Income or Expense',
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

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      if (_selectedIndex == 1) {
        _contactSearchController.clear();
        FocusManager.instance.primaryFocus?.unfocus();
      }
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildHomePage() {
    return ListenableBuilder(
      listenable: widget.settingsRepository.listenable,
      builder: (context, _) => ValueListenableBuilder(
        valueListenable: widget.expenseRepository.listenable,
        builder: (context, box, _) {
          List<Expense> expenses;
          try {
            expenses = widget.expenseRepository.getAll();
          } catch (e) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load your data. Please restart the app.',
                  style: const TextStyle(
                    color: AppColors.snackbarError,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final filteredExpenses = filterExpensesByPeriod(
            expenses,
            _selectedPeriod,
          );
          double totalIncome = 0;
          double totalExpense = 0;
          double totalLent = 0;
          double totalBorrowed = 0;

          for (final expense in filteredExpenses) {
            if (expense.type == TransactionType.income) {
              totalIncome += expense.amount;
            } else if (expense.type == TransactionType.expense) {
              totalExpense += expense.amount;
            } else if (expense.type == TransactionType.lent) {
              totalLent += expense.amount;
            } else if (expense.type == TransactionType.borrowed) {
              totalBorrowed += expense.amount;
            }
          }

          final double availableBalance =
              totalIncome + totalBorrowed - totalExpense - totalLent;
          final double netLending = totalLent - totalBorrowed;
          final currencySymbol = widget.settingsRepository.currencySymbol;

          return ResponsiveContent(
            maxWidth: 760,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: ExpenseSummaryCard(
                    totalBalance: availableBalance,
                    netLending: netLending,
                    totalIncome: totalIncome,
                    totalExpense: totalExpense,
                    totalLent: totalLent,
                    totalBorrowed: totalBorrowed,
                    currencySymbol: currencySymbol,
                    periodLabel: expensePeriodLabel(_selectedPeriod),
                  ),
                ),
                if (filteredExpenses.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: GlassEmptyState(
                          icon: Icons.receipt_long_rounded,
                          title: expenses.isEmpty
                              ? 'No transactions yet'
                              : 'No transactions in this period',
                          message: expenses.isEmpty
                              ? 'Tap add to record income or an expense'
                              : 'Select another month or All Time to view your transactions',
                          action: SizedBox(
                            width: 176,
                            child: GlassButton(
                              onPressed: expenses.isEmpty
                                  ? _navigateAndAddCashFlow
                                  : () => setState(
                                      () => _selectedPeriod = allExpensePeriods,
                                    ),
                              child: Text(
                                expenses.isEmpty
                                    ? 'Add transaction'
                                    : 'View all transactions',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final expense = filteredExpenses[index];
                      final dismissible = Dismissible(
                        key: Key(expense.key.toString()),
                        direction: DismissDirection.horizontal,
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            if (expense.contactName != null &&
                                expense.contactName!.isNotEmpty) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ContactDetailScreen(
                                    contactName: expense.contactName!,
                                    phoneNumber: expense.phoneNumber,
                                    expenseRepository: widget.expenseRepository,
                                    settingsRepository:
                                        widget.settingsRepository,
                                  ),
                                ),
                              );
                            } else {
                              AppSnackbar.show(
                                context: context,
                                message:
                                    'No contact associated with this transaction',
                              );
                            }
                            return false;
                          }
                          return true;
                        },
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
                        background: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: AppColors.highlight,
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.person_rounded,
                                color: AppColors.white,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Contact',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        secondaryBackground: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: AppColors.borrowColor,
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: const Icon(
                            Icons.delete_rounded,
                            color: AppColors.white,
                            size: 28,
                          ),
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
                          key: ValueKey('restored-expense-${expense.key}'),
                          child: dismissible,
                        );
                      }
                      return EntranceMotion(
                        key: ValueKey('expense-${expense.key}'),
                        order: index,
                        child: dismissible,
                      );
                    }, childCount: filteredExpenses.length),
                  ),
                // Add bottom padding to account for FAB and bottom nav bar
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 88,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<String> _availablePeriods() {
    try {
      final periods = availableExpensePeriods(
        widget.expenseRepository.getAll(),
      ).toSet();
      if (_selectedPeriod != allExpensePeriods) periods.add(_selectedPeriod);
      return periods.toList(growable: false)..sort((a, b) => b.compareTo(a));
    } catch (_) {
      return _selectedPeriod == allExpensePeriods
          ? const []
          : [_selectedPeriod];
    }
  }

  Widget _buildPeriodSelector() {
    final periods = _availablePeriods();

    return Semantics(
      button: true,
      label: 'Filter transactions by month',
      value: expensePeriodLabel(_selectedPeriod),
      child: PopupMenuButton<String>(
        initialValue: _selectedPeriod,
        tooltip: 'Select month',
        position: PopupMenuPosition.under,
        color: AppColors.cardSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onSelected: (period) {
          if (period != _selectedPeriod) {
            setState(() => _selectedPeriod = period);
          }
        },
        itemBuilder: (context) => [
          _buildPeriodMenuItem(allExpensePeriods),
          if (periods.isNotEmpty) const PopupMenuDivider(),
          ...periods.map(_buildPeriodMenuItem),
        ],
        child: Container(
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.glassNav,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.glassCardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: AppColors.highlight,
              ),
              const SizedBox(width: 6),
              Text(
                expensePeriodLabel(_selectedPeriod, compact: true),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(width: 2),
              const Icon(Icons.arrow_drop_down_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPeriodMenuItem(String period) {
    final isSelected = period == _selectedPeriod;
    return PopupMenuItem<String>(
      value: period,
      child: Row(
        children: [
          Icon(
            isSelected
                ? Icons.check_circle_rounded
                : Icons.calendar_today_rounded,
            size: 19,
            color: isSelected ? AppColors.highlight : AppColors.secondaryText,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            expensePeriodLabel(period),
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _handleWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressTime != null &&
        now.difference(_lastBackPressTime!) < const Duration(seconds: 2)) {
      return true;
    }
    _lastBackPressTime = now;
    GlassToast.show(
      context: context,
      message: 'Press back again to exit',
      icon: Icons.arrow_back_rounded,
      duration: const Duration(seconds: 2),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomePage(),
      ConnectScreen(
        expenseRepository: widget.expenseRepository,
        settingsRepository: widget.settingsRepository,
        searchController: _contactSearchController,
      ),
      SettingsScreen(settingsRepository: widget.settingsRepository),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _getGreeting(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: _selectedIndex == 0
              ? [
                  ValueListenableBuilder(
                    valueListenable: widget.expenseRepository.listenable,
                    builder: (context, box, child) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Center(child: _buildPeriodSelector()),
                    ),
                  ),
                ]
              : null,
        ),
        body: AppBackground(
          child: IndexedStack(index: _selectedIndex, children: pages),
        ),
        floatingActionButton: _selectedIndex == 0
            ? PressScale(
                pressedScale: 0.94,
                hoverScale: 1.025,
                child: FloatingActionButton(
                  onPressed: _navigateAndAddCashFlow,
                  tooltip: 'Add income or expense',
                  child: const Icon(Icons.add_rounded, size: 26),
                ),
              )
            : null,
        bottomNavigationBar: AppNavBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
