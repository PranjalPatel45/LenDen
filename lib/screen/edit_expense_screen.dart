import 'package:flutter/material.dart';

import '../data/expense_repository.dart';
import '../data/settings_repository.dart';
import '../model/expense_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_snackbar.dart';
import '../utils/app_design.dart';
import '../utils/expense_validation.dart';
import '../utils/transaction_type.dart';
import '../widget/transaction_form.dart';

class EditExpenseScreen extends StatefulWidget {
  final Expense expense;
  final ExpenseRepository expenseRepository;
  final SettingsRepository settingsRepository;

  const EditExpenseScreen({
    super.key,
    required this.expense,
    this.expenseRepository = const ExpenseRepository(),
    this.settingsRepository = const SettingsRepository(),
  });

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  late final TextEditingController titleController;
  late final TextEditingController amountController;
  late final TextEditingController dateController;
  late final TextEditingController reasonController;
  late String? _selectedType;
  String _currencySymbol = '\$';
  bool _isSaving = false;

  List<String> get _allowedTypes {
    if (TransactionType.cashFlowTypes.contains(widget.expense.type)) {
      return TransactionType.cashFlowTypes;
    }
    if (TransactionType.contactTypes.contains(widget.expense.type)) {
      return TransactionType.contactTypes;
    }
    return TransactionType.all;
  }

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.expense.title);
    amountController = TextEditingController(
      text: widget.expense.amount.toString(),
    );
    dateController = TextEditingController(text: widget.expense.date);
    reasonController = TextEditingController(text: widget.expense.reason ?? '');
    _selectedType = widget.expense.type;
    _loadCurrencySymbol();
  }

  void _loadCurrencySymbol() {
    _currencySymbol = widget.settingsRepository.currencySymbol;
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    dateController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Transaction')),
      body: AppBackground(
        child: ResponsiveContent(
          child: TransactionForm(
            headerTitle: 'Update details',
            headerSubtitle: 'Changes are saved to this transaction.',
            amountController: amountController,
            titleController: titleController,
            dateController: dateController,
            reasonController: reasonController,
            selectedType: _selectedType,
            allowedTypes: _allowedTypes,
            currencySymbol: _currencySymbol,
            typeItemTextColor: AppColors.primaryText,
            onTypeChanged: (value) => setState(() => _selectedType = value),
            onDateTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate:
                    DateTime.tryParse(dateController.text) ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (pickedDate != null) {
                dateController.text = pickedDate.toIso8601String().split(
                  'T',
                )[0];
              }
            },
            onCancel: () => Navigator.pop(context),
            onSubmit: () async {
              final validation = validateExpenseInput(
                title: titleController.text,
                amountText: amountController.text,
                date: dateController.text,
                type: _selectedType,
                allowedTypes: _allowedTypes,
              );
              if (!validation.isValid) {
                AppSnackbar.showError(
                  context: context,
                  message: validation.errorMessage!,
                );
                return;
              }
              final amount = validation.amount!;
              if (_isSaving) return;
              _isSaving = true;

              final previousTitle = widget.expense.title;
              final previousAmount = widget.expense.amount;
              final previousDate = widget.expense.date;
              final previousType = widget.expense.type;
              final previousReason = widget.expense.reason;

              try {
                widget.expense.title = titleController.text;
                widget.expense.amount = amount;
                widget.expense.date = dateController.text;
                widget.expense.type = _selectedType!;
                widget.expense.reason = reasonController.text.isNotEmpty
                    ? reasonController.text
                    : null;

                await widget.expenseRepository.save(widget.expense);

                if (!context.mounted) return;
                AppSnackbar.showSuccess(
                  context: context,
                  message: 'Expense saved',
                );

                Navigator.pop(context);
              } catch (e) {
                widget.expense.title = previousTitle;
                widget.expense.amount = previousAmount;
                widget.expense.date = previousDate;
                widget.expense.type = previousType;
                widget.expense.reason = previousReason;
                if (context.mounted) {
                  AppSnackbar.showError(
                    context: context,
                    message: 'Failed to save transaction.',
                  );
                }
              } finally {
                _isSaving = false;
              }
            },
            submitLabel: 'Save',
          ),
        ),
      ),
    );
  }
}
