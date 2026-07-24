import 'package:flutter_test/flutter_test.dart';
import 'package:to_do/model/expense_model.dart';
import 'package:to_do/utils/expense_period.dart';

Expense expense(String date, {String type = 'Lent', double amount = 1}) =>
    Expense(title: 'Test', amount: amount, date: date, type: type);

void main() {
  group('expense period filtering', () {
    final expenses = [
      expense('2026-06-10'),
      expense('2026-07-20'),
      expense('2026-07-01', type: 'Borrowed'),
      expense('invalid-date'),
    ];

    test('creates unique month options newest first', () {
      expect(availableExpensePeriods(expenses), ['2026-07', '2026-06']);
    });

    test('filters only transactions from the selected month', () {
      final filtered = filterExpensesByPeriod(expenses, '2026-07');

      expect(filtered, hasLength(2));
      expect(filtered.every((item) => item.date.startsWith('2026-07')), isTrue);
    });

    test('All Time preserves every transaction including legacy dates', () {
      expect(
        filterExpensesByPeriod(expenses, allExpensePeriods),
        hasLength(expenses.length),
      );
    });

    test('formats full and compact period labels', () {
      expect(expensePeriodLabel('2026-07'), 'July 2026');
      expect(expensePeriodLabel('2026-07', compact: true), 'Jul 2026');
      expect(expensePeriodLabel(allExpensePeriods), 'All Time');
    });
  });
}
