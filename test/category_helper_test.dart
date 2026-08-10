import 'package:flutter_test/flutter_test.dart';
import 'package:to_do/utils/category_helper.dart';

void main() {
  group('parseCategoryAndReason', () {
    test('parses null and empty string', () {
      final resNull = parseCategoryAndReason(null);
      expect(resNull.category, isNull);
      expect(resNull.cleanReason, '');

      final resEmpty = parseCategoryAndReason('   ');
      expect(resEmpty.category, isNull);
      expect(resEmpty.cleanReason, '');
    });

    test('parses category and note separated by pipe', () {
      final res = parseCategoryAndReason('Category: Food | Dinner with friends');
      expect(res.category, 'Food');
      expect(res.cleanReason, 'Dinner with friends');
    });

    test('parses category only', () {
      final res = parseCategoryAndReason('Category: Shopping');
      expect(res.category, 'Shopping');
      expect(res.cleanReason, '');
    });

    test('parses reason without category prefix', () {
      final res = parseCategoryAndReason('Monthly rent payment');
      expect(res.category, isNull);
      expect(res.cleanReason, 'Monthly rent payment');
    });

    test('handles multiple pipes in reason', () {
      final res = parseCategoryAndReason('Category: Utility | Electricity | July');
      expect(res.category, 'Utility');
      expect(res.cleanReason, 'Electricity | July');
    });
  });

  group('formatCategoryAndReason', () {
    test('formats both category and reason', () {
      expect(
        formatCategoryAndReason(category: 'Food', reason: 'Lunch'),
        'Category: Food | Lunch',
      );
    });

    test('formats category only', () {
      expect(
        formatCategoryAndReason(category: 'Salary', reason: ''),
        'Category: Salary',
      );
      expect(
        formatCategoryAndReason(category: ' Salary ', reason: null),
        'Category: Salary',
      );
    });

    test('formats reason only', () {
      expect(
        formatCategoryAndReason(category: null, reason: 'Gas refill'),
        'Gas refill',
      );
      expect(
        formatCategoryAndReason(category: '', reason: 'Gas refill'),
        'Gas refill',
      );
    });

    test('returns null when both are empty', () {
      expect(formatCategoryAndReason(category: null, reason: null), isNull);
      expect(formatCategoryAndReason(category: '  ', reason: '  '), isNull);
    });
  });
}
