import 'package:intl/intl.dart';

import '../model/expense_model.dart';

const String allExpensePeriods = 'all';

final DateFormat _fullPeriodFormat = DateFormat('MMMM yyyy');
final DateFormat _compactPeriodFormat = DateFormat('MMM yyyy');

String? expensePeriodKey(String storedDate) {
  final date = DateTime.tryParse(storedDate);
  if (date == null) return null;
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}';
}

String expensePeriodLabel(String period, {bool compact = false}) {
  if (period == allExpensePeriods) return compact ? 'All' : 'All Time';

  final date = DateTime.tryParse('$period-01');
  if (date == null) return period;
  return (compact ? _compactPeriodFormat : _fullPeriodFormat).format(date);
}

List<String> availableExpensePeriods(Iterable<Expense> expenses) {
  final periods = <String>{};
  for (final expense in expenses) {
    final period = expensePeriodKey(expense.date);
    if (period != null) periods.add(period);
  }
  return periods.toList(growable: false)..sort((a, b) => b.compareTo(a));
}

List<Expense> filterExpensesByPeriod(
  Iterable<Expense> expenses,
  String period,
) {
  if (period == allExpensePeriods) {
    return expenses.toList(growable: false);
  }
  return expenses
      .where((expense) => expensePeriodKey(expense.date) == period)
      .toList(growable: false);
}
