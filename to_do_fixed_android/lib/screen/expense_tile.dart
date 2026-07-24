import 'package:flutter/material.dart';
import 'package:to_do/model/expense_model.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;

  const ExpenseTile({
    super.key,
    required this.expense,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: expense.type == 'Borrowed' ? Colors.green[50] : Colors.red[50],
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(
          expense.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          expense.date,
          style: TextStyle(color: Colors.grey[700]),
        ),
        trailing: Text(
          '\$${expense.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: expense.type == 'Borrowed' ? Colors.green[700] : Colors.red[700],
          ),
        ),
        onLongPress: onDelete, // Allow deletion on long press
      ),
    );
  }
}