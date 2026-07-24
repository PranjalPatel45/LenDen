class ExpenseValidationResult {
  const ExpenseValidationResult._({this.amount, this.errorMessage});

  const ExpenseValidationResult.valid(double amount) : this._(amount: amount);

  const ExpenseValidationResult.invalid(String message)
    : this._(errorMessage: message);

  final double? amount;
  final String? errorMessage;

  bool get isValid => errorMessage == null;
}

ExpenseValidationResult validateExpenseInput({
  required String title,
  required String amountText,
  required String date,
  required String? type,
  List<String>? allowedTypes,
}) {
  final amount = double.tryParse(amountText);
  if (title.isEmpty || amount == null || date.isEmpty || type == null) {
    return const ExpenseValidationResult.invalid(
      'Please fill in all required fields',
    );
  }
  if (amount <= 0) {
    return const ExpenseValidationResult.invalid(
      'Amount must be greater than zero',
    );
  }
  if (allowedTypes != null && !allowedTypes.contains(type)) {
    return const ExpenseValidationResult.invalid(
      'Please select a valid transaction type',
    );
  }
  return ExpenseValidationResult.valid(amount);
}
