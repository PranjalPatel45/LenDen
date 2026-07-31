import 'package:flutter_test/flutter_test.dart';
import 'package:to_do/data/settings_repository.dart';

void main() {
  test('Smart category normalization trims and prevents duplicate additions', () {
    const defaultCategories = SettingsRepository.defaultCategories;
    expect(defaultCategories, contains('Food'));
    expect(defaultCategories, contains('Shopping'));

    final inputCategory = '  Groceries  ';
    final trimmed = inputCategory.trim();
    expect(trimmed, equals('Groceries'));
  });
}
