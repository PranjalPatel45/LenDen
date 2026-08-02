import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../model/expense_model.dart';

/// Provides the single persistence boundary for expense records.
///
/// The repository intentionally uses the existing Hive box and [Expense]
/// adapter so that stored data remains fully backward compatible.
class ExpenseRepository {
  const ExpenseRepository();

  static const String boxName = 'expenses';

  Box<Expense> get _box => Hive.box<Expense>(boxName);

  ValueListenable<Box<Expense>> get listenable => _box.listenable();

  List<Expense> getAll() => List<Expense>.unmodifiable(_box.values);

  Future<int> add(Expense expense) => _box.add(expense);

  Future<dynamic> delete(Expense expense) async {
    final key = expense.key;
    if (key == null) {
      throw StateError('Cannot delete an expense without a Hive key.');
    }
    await _box.delete(key);
    return key;
  }

  Future<void> restore(Expense expense, {dynamic originalKey}) async {
    if (originalKey == null) {
      await _box.add(expense);
      return;
    }
    await _box.put(originalKey, expense);
  }

  Future<void> save(Expense expense) => expense.save();
}
