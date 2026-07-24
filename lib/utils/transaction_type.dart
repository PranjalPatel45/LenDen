class TransactionType {
  const TransactionType._();

  static const String income = 'Income';
  static const String expense = 'Expense';
  static const String lent = 'Lent';
  static const String borrowed = 'Borrowed';

  static const List<String> cashFlowTypes = [income, expense];
  static const List<String> contactTypes = [lent, borrowed];
  static const List<String> all = [income, expense, lent, borrowed];

  static bool isPositive(String type) => type == income || type == borrowed;

  static bool isContactType(String type) => type == lent || type == borrowed;
}
