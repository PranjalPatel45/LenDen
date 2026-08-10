import 'package:flutter_test/flutter_test.dart';
import 'package:to_do/model/expense_model.dart';
import 'package:to_do/utils/report_helper.dart';

void main() {
  final sampleExpenses = [
    Expense(
      title: 'Food',
      amount: 45.0,
      date: '2026-08-01',
      type: 'Expense',
      reason: 'Category: Food | Dinner',
    ),
    Expense(
      title: 'Alice',
      amount: 100.0,
      date: '2026-08-02',
      type: 'Lent',
      contactName: 'Alice',
      phoneNumber: '+1234567890',
    ),
  ];

  group('ReportHelper CSV', () {
    test('generates csv header and lines', () {
      final csv = ReportHelper.generateCsvReport(sampleExpenses);
      expect(csv, contains('Date,Type,Title / Contact,Category,Amount,Reason,Phone'));
      expect(csv, contains('2026-08-01,Expense,Food,Food,45.00,Dinner,'));
      expect(csv, contains('2026-08-02,Lent,Alice,Uncategorized,100.00,,+1234567890'));
    });
  });

  group('ReportHelper JSON Backup & Restore', () {
    test('exports and parses json backup', () {
      final jsonStr = ReportHelper.generateJsonBackup(sampleExpenses);
      expect(jsonStr, contains('"title": "Food"'));
      expect(jsonStr, contains('"contactName": "Alice"'));

      final restored = ReportHelper.parseJsonBackup(jsonStr);
      expect(restored, hasLength(2));
      expect(restored.first.title, 'Food');
      expect(restored.first.amount, 45.0);
      expect(restored.last.contactName, 'Alice');
    });
  });
}
