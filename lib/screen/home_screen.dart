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
import '../utils/app_motion.dart';
import '../utils/expense_period.dart';
import '../utils/delete_restore.dart';
import '../utils/transaction_type.dart';
import '../utils/glass_toast.dart';
import '../utils/app_transitions.dart';
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
  final Set<dynamic> _restoredExpenseKeys = <dynamic>{};
  int _selectedIndex = 0;
  String _selectedPeriod = allExpensePeriods;
  String _selectedCategoryFilter = 'All';
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

  void _onExpenseTileTap(Expense expense) {
    if (TransactionType.isContactType(expense.type)) {
      final contactName = expense.contactName?.trim();
      if (contactName != null && contactName.isNotEmpty) {
        unawaited(
          Navigator.push(
            context,
            AppTransitions.slideRight(
              page: ContactDetailScreen(
                contactName: contactName,
                phoneNumber: expense.phoneNumber,
                expenseRepository: widget.expenseRepository,
                settingsRepository: widget.settingsRepository,
              ),
            ),
          ),
        );
      } else {
        AppSnackbar.showError(
          context: context,
          message: 'Contact details unavailable for this transaction.',
        );
      }
    } else {
      return;
    }
  }

  void _navigateAndAddTransaction({
    List<String>? allowedTypes,
    String? title,
  }) async {
    final newExpense = await Navigator.push<Expense>(
      context,
      AppTransitions.slideUp<Expense>(
        page: AddTodoScreen(
          allowedTypes: allowedTypes ?? TransactionType.cashFlowTypes,
          title: title ?? 'Add Transaction',
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

          // Calculate category frequencies from the current period's expenses
          final Map<String, int> categoryCounts = {};
          for (final expense in filteredExpenses) {
            final cat = expense.category;
            if (cat != null && cat.trim().isNotEmpty) {
              final key = categoryCounts.keys.firstWhere(
                (k) => k.toLowerCase() == cat.trim().toLowerCase(),
                orElse: () => cat.trim(),
              );
              categoryCounts[key] = (categoryCounts[key] ?? 0) + 1;
            }
          }

          final sortedUsedCategories = categoryCounts.keys.toList()
            ..sort((a, b) {
              final countA = categoryCounts[a] ?? 0;
              final countB = categoryCounts[b] ?? 0;
              final cmp = countB.compareTo(countA);
              if (cmp != 0) return cmp;
              return a.compareTo(b);
            });

          final availableCategories = ['All', ...sortedUsedCategories];

          List<Expense> displayedExpenses = filteredExpenses;
          if (_selectedCategoryFilter != 'All') {
            final match = availableCategories.any(
              (c) => c.toLowerCase() == _selectedCategoryFilter.toLowerCase(),
            );
            if (match) {
              displayedExpenses = filteredExpenses.where((e) {
                final cat = e.category ?? '';
                return cat.toLowerCase() ==
                    _selectedCategoryFilter.toLowerCase();
              }).toList();
            }
          }

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
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: availableCategories.map((cat) {
                          final isSelected = cat.toLowerCase() ==
                              _selectedCategoryFilter.toLowerCase();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat),
                              selected: isSelected,
                              selectedColor:
                                  AppColors.primary.withValues(alpha: 0.16),
                              checkmarkColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.primaryText
                                          .withValues(alpha: 0.10),
                                ),
                              ),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.primaryText,
                              ),
                              onSelected: (_) {
                                setState(() => _selectedCategoryFilter = cat);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                if (displayedExpenses.isEmpty)
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
                              ? 'Tap + to record income, expenses, or money with contacts'
                              : 'Select another month or All Time to view your transactions',
                          action: SizedBox(
                            width: 196,
                            child: GlassButton(
                              onPressed: expenses.isEmpty
                                  ? () => _navigateAndAddTransaction()
                                  : () => setState(
                                        () =>
                                            _selectedPeriod = allExpensePeriods,
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
                      final expense = displayedExpenses[index];
                      final swipeTile = TransactionSwipeTile(
                        key: ValueKey('swipe-expense-${expense.key}'),
                        expense: expense,
                        currencySymbol: currencySymbol,
                        onTap: () => _onExpenseTileTap(expense),
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
                          key: ValueKey('restored-expense-${expense.key}'),
                          child: swipeTile,
                        );
                      }
                      return EntranceMotion(
                        key: ValueKey('expense-${expense.key}'),
                        order: index,
                        child: swipeTile,
                      );
                    }, childCount: displayedExpenses.length),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 92,
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
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.glassNav,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.glassCardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 17,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  expensePeriodLabel(_selectedPeriod, compact: true),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
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
            color: isSelected ? AppColors.primary : AppColors.secondaryText,
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
          child: AppTransitions.tabSwitch(
            index: _selectedIndex,
            child: pages[_selectedIndex],
          ),
        ),
        floatingActionButton: _selectedIndex == 0
            ? PressScale(
                pressedScale: 0.94,
                hoverScale: 1.025,
                child: FloatingActionButton(
                  onPressed: () => _navigateAndAddTransaction(),
                  tooltip: 'Add transaction',
                  child: const Icon(Icons.add_rounded, size: 28),
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
