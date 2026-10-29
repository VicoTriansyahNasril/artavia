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
      final day = DateTime(date.year, date.month, date.day);
      final rows = await DatabaseHelper.instance
          .readTransactionsByRange(day, day.add(const Duration(days: 1)));
      selectedDayTransactions.value =
          rows.map(TransactionModel.fromDbRow).toList();
    } finally {
      isLoadingDetail.value = false;
    }
  }

  int get monthIncome =>
      dailyData.values.fold(0, (s, d) => s + (d['income'] ?? 0));
  int get monthExpense =>
      dailyData.values.fold(0, (s, d) => s + (d['expense'] ?? 0));

  /// "Hari ini" chip: jump the grid and the list back to today.
  void goToday() {
    final now = DateTime.now();
    final sameMonth = focusedDay.value.year == now.year &&
        focusedDay.value.month == now.month;
    onDaySelected(now, now);
    if (!sameMonth) loadMonth(now);
  }

  int get selectedDayExpense {
    final normalized = DateTime(
        selectedDay.value.year, selectedDay.value.month, selectedDay.value.day);
    return dailyData[normalized]?['expense'] ?? 0;
  }

  int get selectedDayIncome {
    final normalized = DateTime(
        selectedDay.value.year, selectedDay.value.month, selectedDay.value.day);
    return dailyData[normalized]?['income'] ?? 0;
  }
}
