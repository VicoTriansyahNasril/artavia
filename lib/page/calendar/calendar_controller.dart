import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/model/transaction_model.dart';

class CalendarController extends GetxController {
  final focusedDay = DateTime.now().obs;
  final selectedDay = DateTime.now().obs;

  // key: DateTime(y,m,d) → {expense, income}
  final dailyData = <DateTime, Map<String, int>>{}.obs;

  // Transactions for the selected day
  final selectedDayTransactions = <TransactionModel>[].obs;
  final isLoadingDetail = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadMonth(DateTime.now());
    loadDayTransactions(DateTime.now());
  }

  void onDaySelected(DateTime sDay, DateTime fDay) {
    selectedDay.value = sDay;
    focusedDay.value = fDay;
    loadDayTransactions(sDay);
  }

  void onPageChanged(DateTime newFocused) {
    focusedDay.value = newFocused;
    loadMonth(newFocused);
  }

  Future<void> loadMonth(DateTime date) async {
    final transactions = await DatabaseHelper.instance
        .readTransactionsByMonth(date.year, date.month);

    final Map<DateTime, Map<String, int>> newData = {};
    for (var t in transactions) {
      final d = DateTime.parse(t['date'] as String);
      final key = DateTime(d.year, d.month, d.day);
      final amt = t['amount'] as int;
      final type = t['type'] as String;

      if (!newData.containsKey(key)) {
        newData[key] = {'expense': 0, 'income': 0};
      }
      if (type == 'pengeluaran') {
        newData[key]!['expense'] = (newData[key]!['expense'] ?? 0) + amt;
      } else if (type == 'pemasukan') {
        newData[key]!['income'] = (newData[key]!['income'] ?? 0) + amt;
      }
    }
    dailyData.value = newData;
  }

  Future<void> loadDayTransactions(DateTime date) async {
    isLoadingDetail.value = true;
    try {
      final allTx = await DatabaseHelper.instance
          .readTransactionsByMonth(date.year, date.month);

      final dayTx = allTx.where((t) {
        final d = DateTime.parse(t['date'] as String);
        return d.year == date.year &&
            d.month == date.month &&
            d.day == date.day;
      }).toList();

      selectedDayTransactions.value = dayTx.map((row) {
        final type = row['type'] as String;
        final amt = row['amount'] as int;
        return TransactionModel(
          id: row['id'] as int,
          amount: type == 'pemasukan' ? amt : -amt,
          date: DateTime.parse(row['date'] as String),
          note: row['note'] as String,
          type: type,
          categoryId: row['category_id'] as int?,
          categoryName: row['categoryName'] as String?,
          accountId: row['account_id'] as int?,
          accountName: row['accountName'] as String?,
          destinationAccountId: row['destination_account_id'] as int?,
          destinationAccountName: row['destinationAccountName'] as String?,
          categoryIconCode: row['categoryIconCode'] as int?,
          categoryColorVal: row['categoryColorVal'] as int?,
        );
      }).toList();
    } finally {
      isLoadingDetail.value = false;
    }
  }

  int get selectedDayExpense {
    final normalized = DateTime(selectedDay.value.year,
        selectedDay.value.month, selectedDay.value.day);
    return dailyData[normalized]?['expense'] ?? 0;
  }

  int get selectedDayIncome {
    final normalized = DateTime(selectedDay.value.year,
        selectedDay.value.month, selectedDay.value.day);
    return dailyData[normalized]?['income'] ?? 0;
  }
}
