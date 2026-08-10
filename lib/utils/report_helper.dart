import 'dart:convert';
import '../model/expense_model.dart';
import 'category_helper.dart';

class ReportHelper {
  const ReportHelper._();

  /// Generates a CSV report string from a list of expenses.
  static String generateCsvReport(List<Expense> expenses) {
    final buffer = StringBuffer();
    buffer.writeln('Date,Type,Title / Contact,Category,Amount,Reason,Phone');

    for (final expense in expenses) {
      final categoryReason = parseCategoryAndReason(expense.reason);
      final category = categoryReason.category ?? 'Uncategorized';
      final cleanReason = categoryReason.cleanReason;
      final titleOrContact = expense.contactName ?? expense.title;

      final row = [
        _escapeCsv(expense.date),
        _escapeCsv(expense.type),
        _escapeCsv(titleOrContact),
        _escapeCsv(category),
        expense.amount.toStringAsFixed(2),
        _escapeCsv(cleanReason),
        _escapeCsv(expense.phoneNumber ?? ''),
      ];

      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  /// Encodes expenses into a JSON backup string.
  static String generateJsonBackup(List<Expense> expenses) {
    final list = expenses.map((e) => {
      'title': e.title,
      'amount': e.amount,
      'date': e.date,
      'type': e.type,
      'contactName': e.contactName,
      'phoneNumber': e.phoneNumber,
      'reason': e.reason,
    }).toList();

    return const JsonEncoder.withIndent('  ').convert(list);
  }

  /// Parses JSON backup string into a list of Expense objects.
  static List<Expense> parseJsonBackup(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! List) return [];

    return decoded.map<Expense>((item) {
      final map = item as Map<String, dynamic>;
      return Expense(
        title: map['title']?.toString() ?? 'Untitled',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        date: map['date']?.toString() ?? '',
        type: map['type']?.toString() ?? 'Expense',
        contactName: map['contactName']?.toString(),
        phoneNumber: map['phoneNumber']?.toString(),
        reason: map['reason']?.toString(),
      );
    }).toList();
  }

  static String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      final escaped = field.replaceAll('"', '""');
      return '"$escaped"';
    }
    return field;
  }
}
