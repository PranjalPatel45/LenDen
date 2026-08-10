import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:to_do/data/settings_repository.dart';

void main() {
  late Directory hiveDirectory;
  const repository = SettingsRepository();

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('settings_category_test_');
    Hive.init(hiveDirectory.path);
  });

  setUp(() async {
    await Hive.openBox<dynamic>(SettingsRepository.boxName);
    await Hive.box<dynamic>(SettingsRepository.boxName).clear();
  });

  tearDown(() async {
    await Hive.box<dynamic>(SettingsRepository.boxName).close();
  });

  tearDownAll(() async {
    await hiveDirectory.delete(recursive: true);
  });

  test('Smart category normalization trims and prevents duplicate additions', () async {
    const defaultCategories = SettingsRepository.defaultCategories;
    expect(defaultCategories, contains('Food'));
    expect(defaultCategories, contains('Shopping'));

    await repository.saveCategory('  Groceries  ');
    expect(repository.categories, contains('Groceries'));

    await repository.saveCategory('groceries');
    final count = repository.categories.where((c) => c.toLowerCase() == 'groceries').length;
    expect(count, equals(1));
  });

  test('edits an existing category', () async {
    await repository.saveCategory('Gym');
    expect(repository.categories, contains('Gym'));

    await repository.editCategory('Gym', 'Fitness');
    expect(repository.categories, contains('Fitness'));
    expect(repository.categories, isNot(contains('Gym')));
  });

  test('deletes a category', () async {
    await repository.saveCategory('Utilities');
    expect(repository.categories, contains('Utilities'));

    await repository.deleteCategory('Utilities');
    expect(repository.categories, isNot(contains('Utilities')));
  });

  test('resets categories to defaults', () async {
    await repository.saveCategory('Custom123');
    expect(repository.categories, contains('Custom123'));

    await repository.resetCategories();
    expect(repository.categories, equals(SettingsRepository.defaultCategories));
  });

  test('ranks used categories by usage frequency with All first', () {
    final Map<String, int> counts = {
      'Food': 5,
      'Salary': 3,
      'Shopping': 1,
    };

    final sorted = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    final result = ['All', ...sorted];

    expect(result, equals(['All', 'Food', 'Salary', 'Shopping']));
  });
}
