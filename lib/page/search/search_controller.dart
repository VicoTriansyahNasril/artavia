import 'package:get/get.dart';
import 'package:artavia/model/transaction_model.dart';
import 'package:artavia/core/database/database_helper.dart';

class SearchController extends GetxController {
  final searchQuery = ''.obs;
  final filterType = 'Semua'.obs; // Semua, Pengeluaran, Pemasukan

  final filteredTransactions = <TransactionModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(searchQuery, (_) => doSearch());
    ever(filterType, (_) => doSearch());
    doSearch();
  }

  Future<void> doSearch() async {
    isLoading.value = true;
    try {
      final rawData = await DatabaseHelper.instance.searchTransactions(searchQuery.value);
      
      final List<TransactionModel> results = [];
      for (var row in rawData) {
        final type = row['type'] as String;
        
        bool matchFilter = true;
        if (filterType.value == 'Pengeluaran') {
          matchFilter = type == 'pengeluaran';
        } else if (filterType.value == 'Pemasukan') {
          matchFilter = type == 'pemasukan';
        }
        
        if (matchFilter) {
          final amt = row['amount'] as int;
          results.add(TransactionModel(
            id: row['id'].toString(),
            amount: type == 'pemasukan' ? amt : -amt,
            date: DateTime.parse(row['date'] as String),
            note: row['note'] as String,
            type: type,
            categoryName: row['category'] as String,
            account: row['account'] as String,
          ));
        }
      }
      
      filteredTransactions.value = results;
    } catch (e) {
      Get.log('Search error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
