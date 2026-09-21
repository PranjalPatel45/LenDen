import 'package:flutter_test/flutter_test.dart';
import 'package:to_do/model/expense_model.dart';
import 'package:to_do/utils/report_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('ReportHelper PDF', () {
    test('generates non-empty pdf byte array', () async {
      final pdfBytes = await ReportHelper.generatePdfReport(
        sampleExpenses,
        currencySymbol: '₹',
        currencyCode: 'INR',
      );
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46]));
    });
  });
}
