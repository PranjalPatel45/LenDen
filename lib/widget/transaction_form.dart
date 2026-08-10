import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/settings_repository.dart';
import '../utils/app_colors.dart';
import '../utils/app_motion.dart';
import '../utils/transaction_type.dart';
import 'category_field.dart';
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
    this.isTitleReadOnly = false,
    this.showTitleField = true,
    this.selectedCategory,
    this.categories = const [],
    this.onCategoryChanged,
    this.settingsRepository = const SettingsRepository(),
    this.isSubmitting = false,
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
  final bool isTitleReadOnly;
  final bool showTitleField;
  final String? selectedCategory;
  final List<String> categories;
  final ValueChanged<String>? onCategoryChanged;
  final SettingsRepository settingsRepository;
  final bool isSubmitting;
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
                fieldLabel: 'Amount',
                hintText: '0.00',
                prefixIcon: Text(
                  currencySymbol,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
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
              if (showTitleField) ...[
                const SizedBox(height: 16),
                GlassInput(
                  controller: titleController,
                  fieldLabel: titleFieldLabel,
                  hintText: isTitleReadOnly ? '' : 'Enter $titleFieldLabel',
                  readOnly: isTitleReadOnly,
                  prefixIcon: isTitleReadOnly
                      ? const Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.highlight,
                        )
                      : titleFieldPrefixIcon,
                  suffixIcon: isTitleReadOnly
                      ? const Icon(
                          Icons.lock_rounded,
                          size: 18,
                          color: AppColors.secondaryText,
                        )
                      : null,
                ),
              ],
              const SizedBox(height: 16),
              ExpenseTypeField(
                selectedType: selectedType,
                fieldLabel: 'Transaction Type',
                types: allowedTypes,
                itemTextColor: typeItemTextColor,
                onChanged: onTypeChanged,
              ),
              if (onCategoryChanged != null &&
                  !TransactionType.isContactType(selectedType ?? '')) ...[
                const SizedBox(height: 16),
                CategoryField(
                  selectedCategory: selectedCategory,
                  categories: categories,
                  onCategorySelected: onCategoryChanged!,
                  settingsRepository: settingsRepository,
                ),
              ],
              const SizedBox(height: 16),
              GlassInput(
                controller: reasonController,
                fieldLabel: 'Reason (Optional)',
                hintText: 'Add a note...',
                prefixIcon: const Icon(
                  Icons.notes_rounded,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 16),
              GlassInput(
                controller: dateController,
                fieldLabel: 'Date',
                hintText: 'Select date',
                prefixIcon: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.secondaryText,
                ),
                suffixIcon: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppColors.secondaryText,
                ),
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
                      onPressed: isSubmitting ? null : onSubmit,
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
