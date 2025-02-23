import 'package:expensetracker/bar_graph/bar_graph.dart';
import 'package:expensetracker/components/my_list_tile.dart';
import 'package:expensetracker/database/expense_database.dart';
import 'package:expensetracker/helper/helper_functions.dart';
import 'package:expensetracker/model/expense.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // controllers
  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  // futures
  Future<Map<String, double>>? _monthlyTotalsFuture;
  Future<double>? _calculateCurrentMonthTotal;

  // read
  @override
  void initState() {
    // read the database initial startup
    Provider.of<ExpenseDatabase>(context, listen: false).readExpenses();

    // load futures
    refreshData();

    super.initState();
  }

  // refresh the graph bar
  void refreshData() {
    _monthlyTotalsFuture = Provider.of<ExpenseDatabase>(context, listen: false)
        .calculateMontlyTotals();
    _calculateCurrentMonthTotal =
        Provider.of<ExpenseDatabase>(context, listen: false)
            .calculateCurrentMonthTotal();
  }

  // open new box
  void openNewExpenseBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // expense name
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: "Name",
              ),
            ),
            // expense amount
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                hintText: "Amount",
              ),
            )
          ],
        ),
        actions: [
          // cancel
          _cancelButton(),

          // save
          _createNewExpenseButton(),
        ],
      ),
    );
  }

  // open edit box
  void openEditBox(Expense expense) {
    // prefill the existing info
    String existingName = expense.name;
    String existingAmount = expense.amount.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // expense name
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: existingName,
              ),
            ),
            // expense amount
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                hintText: existingAmount,
              ),
            )
          ],
        ),
        actions: [
          // cancel
          _cancelButton(),

          // save
          _editExpenseButton(expense),
        ],
      ),
    );
  }

  // open delete box
  void openDeleteBox(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit expense"),
        actions: [
          // cancel
          _cancelButton(),

          // delete
          _deleteExpenseButton(expense.id),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseDatabase>(builder: (context, value, child) {
      // get dates
      int startMonth = value.getStartMonth();
      int startYear = value.getStartYear();
      int currentMonth = DateTime.now().month;
      int currentYear = DateTime.now().year;

      // calculate the number of months since the first month
      int monthCount =
          calculateMonthCount(startYear, startMonth, currentYear, currentMonth);

      // display all of the expesnes for the current month
      List<Expense> currentMonthExpense = value.allExpenses.where((expense) {
        return expense.date.year == currentYear &&
            expense.date.month == currentMonth;
      }).toList();

      return Scaffold(
        backgroundColor: Colors.grey.shade300,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: FutureBuilder(
            future: _calculateCurrentMonthTotal,
            builder: (context, snapshot) {
              // loaded
              if (snapshot.connectionState == ConnectionState.done) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // amount
                    Text('\$${snapshot.data!.toStringAsFixed(2)}'),

                    // the month
                    Text(getCurrentMonthName()),
                  ],
                );
              }
              // loading
              else {
                return const Text("Loading...");
              }
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: openNewExpenseBox,
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // GRAPH UI
              SizedBox(
                height: 250,
                child: FutureBuilder(
                  future: _monthlyTotalsFuture,
                  builder: (context, snapshot) {
                    // data is loaded
                    if (snapshot.connectionState == ConnectionState.done) {
                      Map<String, double> monthlyTotals = snapshot.data ?? {};

                      // create the list of monthly summary
                      List<double> monthlySummary = List.generate(
                        monthCount,
                        (index) {
                          // calculate year and month
                          int year = startYear + (startMonth + index - 1) ~/ 12;
                          int month = (startMonth + index - 1) % 12 + 1;

                          // create the key for
                          String yearMonthKey = '$year-$month';

                          // return
                          return monthlyTotals[yearMonthKey] ?? 0.0;
                        },
                      );

                      return MyBarGraph(
                          monthlySummary: monthlySummary,
                          startMonth: startMonth);
                    }

                    // data is loading
                    else {
                      return const Center(
                        child: Text("Loading..."),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(
                height: 25,
              ),

              // LIST OF EXPENSES UI
              Expanded(
                child: ListView.builder(
                  itemCount: currentMonthExpense.length,
                  itemBuilder: (context, index) {
                    // reverse the shown
                    int reversedIndex = currentMonthExpense.length - 1 - index;

                    // get individual expense
                    Expense individualExpense =
                        currentMonthExpense[reversedIndex];

                    // return list tiles
                    return MyListTile(
                      title: individualExpense.name,
                      trailing: formatDouble(individualExpense.amount),
                      onEditPressed: (context) =>
                          openEditBox(individualExpense),
                      onDeletePressed: (context) =>
                          openDeleteBox(individualExpense),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // CANCEL BUTTON
  Widget _cancelButton() {
    return MaterialButton(
      onPressed: () {
        // pop
        Navigator.pop(context);

        // clear textfeilds
        nameController.clear();
        amountController.clear();
      },
      child: const Text("Cancel"),
    );
  }

  // SAVE BUTTON -> create new expense
  Widget _createNewExpenseButton() {
    return MaterialButton(
      onPressed: () async {
        // only save if there is sth in textfeild
        if (nameController.text.isNotEmpty &&
            amountController.text.isNotEmpty) {
          // pop the box
          Navigator.pop(context);

          // create new expense
          Expense newExpense = Expense(
            name: nameController.text,
            amount: convertStringToDouble(amountController.text),
            date: DateTime.now(),
          );

          // save it to db
          await context.read<ExpenseDatabase>().createNewExpense(newExpense);

          // refresh graph
          refreshData();

          // clear the controllers
          nameController.clear();
          amountController.clear();
        } else {}
      },
      child: const Text("Save"),
    );
  }

  // SAVE BUTTON -> edit existing expense
  Widget _editExpenseButton(Expense expense) {
    return MaterialButton(
      onPressed: () async {
        // save if at least one textfeild changed
        if (nameController.text.isNotEmpty ||
            amountController.text.isNotEmpty) {
          // pop the box
          Navigator.pop(context);

          // create a new expense button
          Expense updatedExpense = Expense(
            name: nameController.text.isNotEmpty
                ? nameController.text
                : expense.name,
            amount: amountController.text.isNotEmpty
                ? convertStringToDouble(nameController.text)
                : expense.amount,
            date: DateTime.now(),
          );

          // old expense id
          int existingId = expense.id;

          // save to db
          await context
              .read<ExpenseDatabase>()
              .updateExpenses(existingId, updatedExpense);

          // refresh graph
          refreshData();
        }
      },
      child: const Text("Save"),
    );
  }

  // DELETE BUTTON -> delete
  Widget _deleteExpenseButton(int id) {
    return MaterialButton(
      onPressed: () async {
        // pop the box
        Navigator.pop(context);

        // delete the expense
        await context.read<ExpenseDatabase>().deleteExpense(id);

        // refresh graph
        refreshData();
      },
      child: const Text("Delete"),
    );
  }
}
