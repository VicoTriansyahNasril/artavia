import 'package:get/get.dart';
import 'package:artavia/model/transaction_model.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/utils/finance_calc.dart';

class SearchController extends GetxController {
  final searchQuery = ''.obs;
  final filterType = 'Semua'.obs; // Semua, Pengeluaran, Pemasukan, Transfer

  final filteredTransactions = <TransactionModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    debounce(searchQuery, (_) => doSearch(),
        time: const Duration(milliseconds: 250));
    ever(filterType, (_) => doSearch());
    doSearch();
  }

  Future<void> doSearch() async {
    isLoading.value = true;
    try {
      final rows =
          await DatabaseHelper.instance.searchTransactions(searchQuery.value);
      filteredTransactions.value = rows
          .where(
              (r) => matchesTypeFilter(r['type'] as String, filterType.value))
          .map(TransactionModel.fromDbRow)
          .toList();
    } catch (e) {
      Get.log('Search error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
