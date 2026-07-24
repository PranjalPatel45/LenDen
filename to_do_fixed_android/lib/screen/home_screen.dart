import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do/model/expense_model.dart';
import 'package:to_do/screen/form_screen.dart';
import '../model/expense_summary_card.dart';
import '../model/expense_tile.dart';
import 'edit_expense_screen.dart';
import 'connect_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _navigateAndAddExpense() async {
    final newExpense = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(builder: (context) => const AddTodoScreen()),
    );

    // If a new expense is returned, add it to the Hive box.
    if (newExpense != null) {
      final expenseBox = Hive.box<Expense>('expenses');
      expenseBox.add(newExpense);
    }
  }

  void _navigateToEditExpense(Expense expense) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditExpenseScreen(expense: expense)),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildHomePage() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Expense>('expenses').listenable(),
      builder: (context, box, _) {
        final expenses = box.values.toList().cast<Expense>();
        final now = DateTime.now();
        double totalLent = 0;
        double totalBorrowed = 0;

        for (var expense in expenses) {
          final expenseDate = DateTime.tryParse(expense.date);
          if (expenseDate != null &&
              expenseDate.month == now.month &&
              expenseDate.year == now.year) {
            if (expense.type == 'Lent') {
              totalLent += expense.amount;
            } else if (expense.type == 'Borrowed') {
              totalBorrowed += expense.amount;
            }
          }
        }

        final double totalBalance = totalLent - totalBorrowed;

        return Column(
          children: [
            ExpenseSummaryCard(
              totalBalance: totalBalance,
              totalLent: totalLent,
              totalBorrowed: totalBorrowed,
            ),
            if (expenses.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No expenses yet. Add one!'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return Dismissible(
                      key: Key(expense.key.toString()),
                      onDismissed: (direction) {
                        if (direction == DismissDirection.endToStart) {
                          box.deleteAt(index);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Expense deleted')),
                          );
                        }
                      },
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          _navigateToEditExpense(expense);
                          return false; // Do not dismiss for edit
                        } else {
                          return true; // Allow dismissal for delete
                        }
                      },
                      background: Container(
                        color: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerLeft,
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerRight,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ExpenseTile(
                        expense: expense,
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomePage(),
      const ConnectScreen(),
      const Center(child: Text('Settings Page', style: TextStyle(fontSize: 24))),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Manager'),
      ),
      body: pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _navigateAndAddExpense,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Connect'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}