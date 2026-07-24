import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:to_do/utils/app_colors.dart';
import 'package:to_do/utils/snackbar_feedback.dart';

void main() {
  testWidgets('deletion snackbar restores the entry when Undo is pressed', (
    tester,
  ) async {
    var restored = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppColors.theme,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDeletionUndoSnackBar(
                context,
                message: 'Transaction deleted',
                restore: () async => restored = true,
              ),
              child: const Text('Delete'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The overlay snackbar should be visible
    expect(find.text('Transaction deleted'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    // Tap the Undo action
    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(restored, isTrue);

    // After undo, the success message "Transaction restored" should appear
    expect(find.text('Transaction restored'), findsOneWidget);
  });
}