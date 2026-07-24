import 'package:flutter_test/flutter_test.dart';
import 'package:to_do/utils/contact_identity.dart';

void main() {
  group('normalizePhoneNumber', () {
    test('removes formatting without changing digits', () {
      expect(normalizePhoneNumber('+91 (987) 654-3210'), '919876543210');
    });
  });

  group('isExpenseForContact', () {
    test('matches equivalent formatted phone numbers', () {
      expect(
        isExpenseForContact(
          expensePhoneNumber: '+1 (555) 123-4567',
          contactPhoneNumber: '+1 555 123 4567',
          expenseContactName: 'Alex',
          contactName: 'Alex',
        ),
        isTrue,
      );
    });

    test('does not match different phone numbers', () {
      expect(
        isExpenseForContact(
          expensePhoneNumber: '5551234567',
          contactPhoneNumber: '5550000000',
          expenseContactName: 'Alex',
          contactName: 'Alex',
        ),
        isFalse,
      );
    });

    test('uses the contact name when neither side has a phone number', () {
      expect(
        isExpenseForContact(
          expensePhoneNumber: null,
          contactPhoneNumber: null,
          expenseContactName: 'Alex Smith',
          contactName: 'Alex Smith',
        ),
        isTrue,
      );
    });
  });
}
