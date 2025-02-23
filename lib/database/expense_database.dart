import 'package:expensetracker/model/expense.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class ExpenseDatabase extends ChangeNotifier {
  static late Isar isar;
  final List<Expense> _allExpenses = [];

  // initialize app
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [ExpenseSchema], 
      directory: dir.path,
    );
  }


  // getters
  List<Expense> get allExpenses => _allExpenses;


  // create - create the expenses
  Future<void> createNewExpense(Expense newExpense) async {
    // add to db
    await isar.writeTxn(() => isar.expenses.put(newExpense));

    // reread the db
    await readExpenses();
  }

  // read - read the expense
  Future<void> readExpenses() async {
    // fetch all of the existing expenses from db
    List<Expense> fetchExpenses = await isar.expenses.where().findAll();

    // give to local expense list
    _allExpenses.clear();
    _allExpenses.addAll(fetchExpenses);

    // update ui
    notifyListeners();
  }

  // update - update the expenses
  Future<void> updateExpenses(int id, Expense updateExpenses) async {
    // make sure the new id has the same as existing
    updateExpenses.id = id;

    // update the db
    await isar.writeTxn(() => isar.expenses.put(updateExpenses));

    // reread the db
    await readExpenses();
  }

  // delete - delete it
  Future<void> deleteExpense(int id) async {
    // delete from db
    await isar.writeTxn(() => isar.expenses.delete(id));

    // reread the db
    await readExpenses();
  }


  // calculate total expenses for each month
  Future<Map<String, double>> calculateMontlyTotals() async {
    // ensure that the expenses are read from the db
    await readExpenses();

    // create a map to keep track of total monthly expneses
    Map<String, double> monthlyTotals = {
      // 0: 250 jan

      // 1: 100 feb 

    };

    // iterite all of the expenses
    for (var expense in _allExpenses) {
      // extract the month from the data of the each expneses
      String yearMonth = 
          '${expense.date.year}-${expense.date.month}';

      // if the map is not yet in the map, initialize to 0
      if (!monthlyTotals.containsKey(yearMonth)) {
        monthlyTotals[yearMonth] = 0;
      }

      // add the expense amount to total for the month
      monthlyTotals[yearMonth] = monthlyTotals[yearMonth]! + expense.amount;
    }
    return monthlyTotals;
  }

  // calculate current month total
  Future<double> calculateCurrentMonthTotal() async {
    // ensure the expenses are read from the db
    await readExpenses();

    // get current month, year
    int currentMonth = DateTime.now().month;
    int currentYear = DateTime.now().year;

    // filter the expenses to include only those for this month this year
    List<Expense> currentMonthExpense = _allExpenses.where((expense) {
      return expense.date.month == currentMonth && expense.date.year == currentYear;
    }).toList();

    // calculate total amount for the current month
    double total = 
        currentMonthExpense.fold(0, (sum, expense) => sum + expense.amount);

    return total;
  }

  // get start month 
  int getStartMonth() {
    if (_allExpenses.isEmpty) {
      return DateTime.now().month;
    }

    // sort the expenses by date to find the earlist
    _allExpenses.sort(
      (a, b) => a.date.compareTo(b.date),
    );

    return _allExpenses.first.date.month;
  }

  // get start year
  int getStartYear() {
    if (_allExpenses.isEmpty) {
      return DateTime.now().year;
    }

    // sort the expenses by date to find the earlist
    _allExpenses.sort(
      (a, b) => a.date.compareTo(b.date),
    );

    return _allExpenses.first.date.year;
  }

}