import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:to_do/data/expense_repository.dart';
import 'package:to_do/model/expense_model.dart';
import 'package:to_do/utils/app_colors.dart';
import 'package:to_do/utils/delete_restore.dart';

void main() {
  late Directory hiveDirectory;
  const repository = ExpenseRepository();

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('delete_restore_');
    Hive.init(hiveDirectory.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ExpenseAdapter());
  });

  setUp(() async {
    await Hive.openBox<Expense>(ExpenseRepository.boxName);
    await Hive.box<Expense>(ExpenseRepository.boxName).clear();
  });

  tearDown(() async => Hive.box<Expense>(ExpenseRepository.boxName).close());
  tearDownAll(() async => hiveDirectory.delete(recursive: true));

  Expense newExpense(String title) =>
      Expense(title: title, amount: 10, date: '2026-08-09', type: 'Expense');

  Future<BuildContext> pumpDeleteButton(WidgetTester tester) async {
    late BuildContext buttonContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppColors.theme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              buttonContext = context;
              return TextButton(onPressed: () {}, child: const Text('Delete'));
            },
          ),
        ),
      ),
    );
    return buttonContext;
  }

  Future<void> delete(BuildContext context, Expense expense) =>
      deleteExpenseWithUndo(
        context: context,
        expense: expense,
        expenseRepository: repository,
        restoredKeys: <dynamic>{},
        onStateChanged: () {},
      );

  testWidgets('only transaction deletion offers Undo', (tester) async {
    final onlyExpense = newExpense('Only');
    await repository.add(onlyExpense);
    final context = await pumpDeleteButton(tester);

    await delete(context, onlyExpense);
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.getAll(), isEmpty);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('deleting one of two transactions offers Undo', (tester) async {
    final firstExpense = newExpense('First');
    await repository.add(firstExpense);
    await repository.add(newExpense('Second'));
    final context = await pumpDeleteButton(tester);

    await delete(context, firstExpense);
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.getAll(), hasLength(1));
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('deleting the remaining transaction offers its own Undo prompt', (
    tester,
  ) async {
    final firstExpense = newExpense('First');
    final secondExpense = newExpense('Second');
    await repository.add(firstExpense);
    await repository.add(secondExpense);
    final context = await pumpDeleteButton(tester);

    await delete(context, firstExpense);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Undo'), findsOneWidget);

    await delete(context, secondExpense);
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.getAll(), isEmpty);
    expect(find.text('Undo'), findsOneWidget);
  });
}
