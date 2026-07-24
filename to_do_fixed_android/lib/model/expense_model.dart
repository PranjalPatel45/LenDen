import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String date;

  @HiveField(3)
  String type;

  Expense({
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
  });
}