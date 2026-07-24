import 'package:flutter_test/flutter_test.dart';
import 'package:to_do/utils/expense_validation.dart';

void main() {
  test('accepts the same complete positive expense input as the forms', () {
    final result = validateExpenseInput(
      title: 'Lunch',
      amountText: '125.50',
      date: '2026-07-20',
      type: 'Lent',
    );

    expect(result.isValid, isTrue);
    expect(result.amount, 125.5);
  });

  test('rejects missing required input', () {
    final result = validateExpenseInput(
      title: '',
      amountText: '125.50',
      date: '2026-07-20',
      type: 'Lent',
    );

    expect(result.isValid, isFalse);
    expect(result.errorMessage, 'Please fill in all required fields');
  });

  test('rejects zero and negative amounts', () {
    for (final amount in ['0', '-1']) {
      final result = validateExpenseInput(
        title: 'Lunch',
        amountText: amount,
        date: '2026-07-20',
        type: 'Borrowed',
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, 'Amount must be greater than zero');
    }
  });
}
