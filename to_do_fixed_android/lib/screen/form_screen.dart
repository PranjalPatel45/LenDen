import 'package:flutter/material.dart';

import '../model/expense_model.dart';

class AddTodoScreen
    extends StatefulWidget {
  const AddTodoScreen({super.key});

  @override
  State<AddTodoScreen> createState() =>
      _AddTodoScreenState();
}

class _AddTodoScreenState
    extends State<AddTodoScreen> {
  final titleController =
  TextEditingController();

  final amountController =
  TextEditingController();

  final dateController =
  TextEditingController();

  String? _selectedType;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding:
        const EdgeInsets.only(top: 100,right: 16,left: 16),
        child: Column(
          children: [

            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.monetization_on_outlined),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),

            const SizedBox(height: 20),
            TextField(
              controller:
              titleController,
              decoration:
              const InputDecoration(
                labelText: 'Title',
              ),
            ),



            const SizedBox(height: 20),


            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                prefixIcon: Icon(Icons.swap_horiz),
              ),
              items: ['Lent', 'Borrowed']
                  .map((label) => DropdownMenuItem(
                value: label,
                child: Text(label),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
              },
            ),
            const SizedBox(height: 20),

            TextField(
              controller:
              dateController,
              decoration: const InputDecoration(
                labelText: 'Date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true, // Prevents keyboard from appearing
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  // Format date as YYYY-MM-DD
                  dateController.text = pickedDate.toIso8601String().split('T')[0];
                }
              },
            ),



            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child:
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                          context);
                    },
                    child:
                    const Text(
                      'Cancel',
                    ),
                  ),
                ),
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                  child:
                  ElevatedButton(
                    onPressed: () {
                      final amount = double.tryParse(amountController.text);
                      if (titleController.text.isEmpty || amount == null || dateController.text.isEmpty || _selectedType == null) {
                        // Optionally, show an error message
                        return;
                      }

                      final newExpense = Expense(
                        title: titleController.text,
                        amount: amount,
                        date: dateController.text,
                        type: _selectedType!,
                      );

                      Navigator.pop(context, newExpense);
                    },
                    child: const Text('Submit'),
                  )
                ),



              ],
            )
          ],
        ),
      ),
    );
  }
}