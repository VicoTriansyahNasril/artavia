import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';

class ProfileController extends GetxController {
  final userName = 'Pengguna Artavia'.obs;
  final totalAccounts = 0.obs;
  final totalCategories = 0.obs;
  final netWorth = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadStats();
  }

  Future<void> loadStats() async {
    final accounts = await DatabaseHelper.instance.readAllAccounts();
    final categories = await DatabaseHelper.instance.readAllCategories();

    int nw = 0;
    for (final acc in accounts) {
      final excluded = acc['is_excluded'] == 1;
      if (!excluded) {
        nw += acc['balance'] as int;
      }
    }

    totalAccounts.value = accounts.length;
    totalCategories.value = categories.length;
    netWorth.value = nw;
  }
}
