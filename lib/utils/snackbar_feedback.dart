import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_snackbar.dart';

void showDeletionUndoSnackBar(
  BuildContext context, {
  required String message,
  required Future<void> Function() restore,
}) {
  AppSnackbar.showWithAction(
    context: context,
    message: message,
    actionLabel: 'Undo',
    backgroundColor: AppColors.snackbarError,
    duration: AppColors.deletionSnackBarDuration,
    onAction: () async {
      try {
        await restore();
        if (context.mounted) {
          AppSnackbar.showSuccess(
            context: context,
            message: 'Transaction restored',
          );
        }
      } catch (error) {
        if (context.mounted) {
          AppSnackbar.showError(
            context: context,
            message: 'Failed to restore: $error',
          );
        }
      }
    },
  );
}