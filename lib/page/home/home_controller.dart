import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:artavia/model/transaction_model.dart';
import 'package:artavia/core/database/database_helper.dart';

class HomeController extends GetxController {
  final isLoading = false.obs;
  final transactions = <TransactionModel>[].obs;
  final totalPengeluaran = 0.obs;
  final totalPemasukan = 0.obs;
  final saldoTotal = 0.obs;
  final currentDate = DateTime.now().obs;
  final hideBalance = false.obs;
  final currentIndex = 0.obs;
  final isFabOpen = false.obs;

  String get currentMonth =>
      DateFormat('MMM', 'id_ID').format(currentDate.value);
  String get currentYear => currentDate.value.year.toString();

  void changePage(int index) {
    currentIndex.value = index;
  }

  void toggleHideBalance() {
    hideBalance.value = !hideBalance.value;
  }

  void prevMonth() {
    currentDate.value = DateTime(
        currentDate.value.year, currentDate.value.month - 1);
    loadData();
  }

  void nextMonth() {
    currentDate.value = DateTime(
        currentDate.value.year, currentDate.value.month + 1);
    loadData();
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      final year = currentDate.value.year;
      final month = currentDate.value.month;
      final dbData =
          await DatabaseHelper.instance.readTransactionsByMonth(year, month);

      int inTotal = 0;
      int exTotal = 0;

      final List<TransactionModel> loaded = [];
      for (var row in dbData) {
        final amt = row['amount'] as int;
        final type = row['type'] as String;

        if (type == 'pemasukan') {
          inTotal += amt;
        } else if (type == 'pengeluaran') {
          exTotal += amt;
        }

        loaded.add(TransactionModel(
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
        ));
      }

      totalPemasukan.value = inTotal;
      totalPengeluaran.value = exTotal;
      saldoTotal.value = inTotal - exTotal;
      transactions.value = loaded;
    } catch (e) {
      Get.log('Error loading data: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
