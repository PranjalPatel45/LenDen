import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_colors.dart';
import '../utils/app_motion.dart';
import 'expense_type_field.dart';
import 'glass_widgets.dart';

/// Shared transaction form layout used by add and edit screens.
class TransactionForm extends StatelessWidget {
  const TransactionForm({
    super.key,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.amountController,
    required this.titleController,
    required this.dateController,
    required this.reasonController,
    required this.selectedType,
    required this.allowedTypes,
    required this.currencySymbol,
    required this.onTypeChanged,
    required this.onDateTap,
    required this.onCancel,
    required this.onSubmit,
    required this.submitLabel,
    this.titleFieldLabel = 'Title',
    this.titleFieldPrefixIcon,
    this.typeItemTextColor = AppColors.primaryText,
    this.submitColor = AppColors.highlight,
    this.submitForegroundColor = AppColors.white,
  });

  final String headerTitle;
  final String headerSubtitle;
  final TextEditingController amountController;
  final TextEditingController titleController;
  final TextEditingController dateController;
  final TextEditingController reasonController;
  final String? selectedType;
  final List<String> allowedTypes;
  final String currencySymbol;
  final ValueChanged<String?> onTypeChanged;
  final VoidCallback onDateTap;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final String submitLabel;
  final String titleFieldLabel;
  final Widget? titleFieldPrefixIcon;
  final Color typeItemTextColor;
  final Color submitColor;
  final Color submitForegroundColor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: EntranceMotion(
        child: GlassCard(
          radius: 18,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headerTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      headerSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GlassInput(
                controller: amountController,
                labelText: 'Amount ($currencySymbol)',
                prefixIcon: Text(
                  currencySymbol,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  LengthLimitingTextInputFormatter(12),
                ],
              ),
              const SizedBox(height: 16),
              GlassInput(
                controller: titleController,
                labelText: titleFieldLabel,
                prefixIcon: titleFieldPrefixIcon,
              ),
              const SizedBox(height: 16),
              ExpenseTypeField(
                selectedType: selectedType,
                types: allowedTypes,
                itemTextColor: typeItemTextColor,
                onChanged: onTypeChanged,
              ),
              const SizedBox(height: 16),
              GlassInput(
                controller: reasonController,
                labelText: 'Reason (optional)',
                prefixIcon: const Icon(Icons.notes),
              ),
              const SizedBox(height: 16),
              GlassInput(
                controller: dateController,
                labelText: 'Date',
                suffixIcon: const Icon(Icons.calendar_today),
                readOnly: true,
                onTap: onDateTap,
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      onPressed: onCancel,
                      radius: 14,
                      color: AppColors.white,
                      foregroundColor: AppColors.primaryText,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: GlassButton(
                      onPressed: onSubmit,
                      radius: 14,
                      color: submitColor,
                      foregroundColor: submitForegroundColor,
                      child: Text(submitLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
