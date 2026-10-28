import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/utils/finance_calc.dart';

/// Aset tab: net worth and accounts grouped by type. Monthly analysis lives
/// in the Grafik tab only (FR-020).
class ReportController extends GetxController {
  final kekayaanBersih = 0.obs;
  final totalAset = 0.obs;
  final totalLiabilitas = 0.obs;

  /// [{groupName, total, accounts: [raw account rows]}]
  final accountGroups = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    final accounts = await DatabaseHelper.instance.readAllAccounts();

    final worth = computeNetWorth(accounts);
    totalAset.value = worth.asset;
    totalLiabilitas.value = worth.liability;
    kekayaanBersih.value = worth.net;

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final acc in accounts) {
      final type = acc['type'] as String? ?? 'Lainnya';
      grouped.putIfAbsent(type, () => []).add(acc);
    }
    accountGroups.value = grouped.entries
        .map((e) => {
              'groupName': e.key,
              'total': computeNetWorth(e.value).net,
              'accounts': e.value,
            })
        .toList();
  }
}
