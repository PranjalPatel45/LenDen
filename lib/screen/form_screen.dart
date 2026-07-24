import 'package:flutter/material.dart';

import 'package:to_do/data/settings_repository.dart';
import 'package:to_do/model/expense_model.dart';
import 'package:to_do/utils/app_snackbar.dart';
import 'package:to_do/utils/app_design.dart';
import 'package:to_do/utils/expense_validation.dart';
import 'package:to_do/utils/transaction_type.dart';
import 'package:to_do/widget/transaction_form.dart';

class AddTodoScreen extends StatefulWidget {
  final String? prefillContactName;
  final String? prefillPhoneNumber;
  final List<String> allowedTypes;
  final String title;

  const AddTodoScreen({
    super.key,
    this.prefillContactName,
    this.prefillPhoneNumber,
    this.allowedTypes = TransactionType.contactTypes,
    this.title = 'Add Transaction',
    this.settingsRepository = const SettingsRepository(),
  });

  final SettingsRepository settingsRepository;

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final dateController = TextEditingController();
  final reasonController = TextEditingController();
  String? _selectedType;
  String _currencySymbol = '\$';

  @override
  void initState() {
    super.initState();
    if (widget.prefillContactName != null) {
      titleController.text = widget.prefillContactName!;
    }
    _loadCurrencySymbol();
    _setDefaultDate();
    _setDefaultType();
  }

  void _loadCurrencySymbol() {
    _currencySymbol = widget.settingsRepository.currencySymbol;
  }

  void _setDefaultDate() {
    final now = DateTime.now();
    dateController.text = now.toIso8601String().split('T')[0];
  }

  void _setDefaultType() {
    _selectedType = widget.allowedTypes.first;
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
      appBar: AppBar(title: Text(widget.title)),
      body: AppBackground(
        child: ResponsiveContent(
          child: TransactionForm(
            headerTitle: 'Transaction details',
            headerSubtitle: 'Add the amount, direction and date.',
            amountController: amountController,
            titleController: titleController,
            dateController: dateController,
            reasonController: reasonController,
            selectedType: _selectedType,
            allowedTypes: widget.allowedTypes,
            currencySymbol: _currencySymbol,
            titleFieldLabel: widget.prefillContactName != null
                ? 'Contact Name'
                : 'Title',
            titleFieldPrefixIcon: widget.prefillContactName != null
                ? const Icon(Icons.person)
                : null,
            onTypeChanged: (value) => setState(() => _selectedType = value),
            onDateTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
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
            onSubmit: () {
              final validation = validateExpenseInput(
                title: titleController.text,
                amountText: amountController.text,
                date: dateController.text,
                type: _selectedType,
                allowedTypes: widget.allowedTypes,
              );
              if (!validation.isValid) {
                AppSnackbar.showError(
                  context: context,
                  message: validation.errorMessage!,
                );
                return;
              }
              final amount = validation.amount!;

              final newExpense = Expense(
                title: titleController.text,
                amount: amount,
                date: dateController.text,
                type: _selectedType!,
                contactName: widget.prefillContactName,
                phoneNumber: widget.prefillPhoneNumber,
                reason: reasonController.text.isNotEmpty
                    ? reasonController.text
                    : null,
              );

              Navigator.pop(context, newExpense);
            },
            submitLabel: 'Submit',
          ),
        ),
      ),
    );
  }
}
