import 'package:flutter/material.dart';

import '../data/expense_repository.dart';
import '../model/expense_model.dart';
import 'app_snackbar.dart';
import 'snackbar_feedback.dart';

/// Handles the delete-with-undo flow for an expense.
///
/// Extracted to avoid duplicating this logic across [HomeScreen] and
/// [ContactDetailScreen].
Future<void> deleteExpenseWithUndo({
  required BuildContext context,
  required Expense expense,
  required ExpenseRepository expenseRepository,
  required Set<dynamic> restoredKeys,
  required VoidCallback onStateChanged,
}) async {
  late final dynamic originalKey;
  try {
    originalKey = await expenseRepository.delete(expense);
  } catch (e) {
    if (context.mounted) {
      AppSnackbar.showError(
        context: context,
        message: 'Failed to delete transaction.',
      );
    }
    return;
  }
  if (!context.mounted) return;

  showDeletionUndoSnackBar(
    context,
    message: 'Transaction deleted',
    restore: () async {
      if (context.mounted) {
        restoredKeys.add(originalKey);
        onStateChanged();
      }
      try {
        await expenseRepository.restore(
          expense,
          originalKey: originalKey,
        );
      } catch (_) {
        if (context.mounted) {
          restoredKeys.remove(originalKey);
          onStateChanged();
        }
        rethrow;
      }
    },
  );
}
