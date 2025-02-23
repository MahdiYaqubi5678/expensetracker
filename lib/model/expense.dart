import 'package:isar/isar.dart';

// line for generator
part 'expense.g.dart';

@Collection()

class Expense {
  Id id = Isar.autoIncrement;
  final String name;
  final double amount;
  final DateTime date;

  Expense({
    required this.name,
    required this.amount,
    required this.date
  });
}