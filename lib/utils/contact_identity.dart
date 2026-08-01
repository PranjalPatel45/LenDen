/// Normalizes formatting characters without making country-code assumptions.
String normalizePhoneNumber(String phoneNumber) =>
    phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

/// Matches existing transactions to a contact.
///
/// Phone number remains the primary identity, preserving current behavior. A
/// name fallback fixes transactions created for contacts that have no number.
bool isExpenseForContact({
  required String? expensePhoneNumber,
  required String? contactPhoneNumber,
  required String? expenseContactName,
  required String contactName,
}) {
  final hasExpensePhone =
      expensePhoneNumber != null && expensePhoneNumber.trim().isNotEmpty;
  final hasContactPhone =
      contactPhoneNumber != null && contactPhoneNumber.trim().isNotEmpty;

  if (hasExpensePhone && hasContactPhone) {
    final expensePhone = normalizePhoneNumber(expensePhoneNumber);
    final contactPhone = normalizePhoneNumber(contactPhoneNumber);
    if (expensePhone.isNotEmpty && contactPhone.isNotEmpty) {
      return expensePhone == contactPhone;
    }
  }

  if (expenseContactName != null && expenseContactName.trim().isNotEmpty) {
    return expenseContactName.trim().toLowerCase() ==
        contactName.trim().toLowerCase();
  }

  return false;
}
