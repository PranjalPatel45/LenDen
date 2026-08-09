import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:to_do/model/expense_model.dart';
import 'package:to_do/widget/expense_tile.dart';

void main() {
  testWidgets('a full swipe only reveals actions and never deletes directly', (
    tester,
  ) async {
    var deleteCalls = 0;
    final expense = Expense(
      title: 'Coffee',
      amount: 5,
      date: '2026-08-09',
      type: 'Expense',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionSwipeTile(
            expense: expense,
            onEdit: () {},
            onDelete: () async {
              deleteCalls++;
            },
          ),
        ),
      ),
    );

    await tester.drag(find.byType(TransactionSwipeTile), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(deleteCalls, 0);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(deleteCalls, 1);
  });
}
