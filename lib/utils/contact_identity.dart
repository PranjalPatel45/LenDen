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
  if (expensePhoneNumber != null && contactPhoneNumber != null) {
    final expensePhone = normalizePhoneNumber(expensePhoneNumber);
    final contactPhone = normalizePhoneNumber(contactPhoneNumber);
    return expensePhone.isNotEmpty && expensePhone == contactPhone;
  }

  return expensePhoneNumber == null &&
      contactPhoneNumber == null &&
      expenseContactName == contactName;
}
