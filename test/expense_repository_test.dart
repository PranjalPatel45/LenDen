import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:to_do/data/expense_repository.dart';
import 'package:to_do/model/expense_model.dart';

void main() {
  late Directory hiveDirectory;
  const repository = ExpenseRepository();

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('lend_tracker_test_');
    Hive.init(hiveDirectory.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ExpenseAdapter());
    }
  });

  setUp(() async {
    await Hive.openBox<Expense>(ExpenseRepository.boxName);
    await Hive.box<Expense>(ExpenseRepository.boxName).clear();
  });

  tearDown(() async {
    await Hive.box<Expense>(ExpenseRepository.boxName).close();
  });

  tearDownAll(() async {
    await hiveDirectory.delete(recursive: true);
  });

  test('adds, saves, deletes, and restores an expense', () async {
    final expense = Expense(
      title: 'Lunch',
      amount: 100,
      date: '2026-07-20',
      type: 'Lent',
    );

    await repository.add(expense);
    expect(repository.getAll(), hasLength(1));

    expense.amount = 125;
    await repository.save(expense);
    expect(repository.getAll().single.amount, 125);

    final originalKey = await repository.delete(expense);
    expect(repository.getAll(), isEmpty);

    await repository.restore(expense, originalKey: originalKey);
    expect(repository.getAll().single.amount, 125);
  });

  test('undo restores an expense to its original position', () async {
    final first = Expense(
      title: 'First',
      amount: 10,
      date: '2026-07-20',
      type: 'Lent',
    );
    final second = Expense(
      title: 'Second',
      amount: 20,
      date: '2026-07-20',
      type: 'Lent',
    );
    final third = Expense(
      title: 'Third',
      amount: 30,
      date: '2026-07-20',
      type: 'Lent',
    );
    await repository.add(first);
    await repository.add(second);
    await repository.add(third);

    final originalKey = await repository.delete(first);
    expect(repository.getAll().map((expense) => expense.title), [
      'Second',
      'Third',
    ]);

    await repository.restore(first, originalKey: originalKey);

    expect(repository.getAll().map((expense) => expense.title), [
      'First',
      'Second',
      'Third',
    ]);
  });
}
