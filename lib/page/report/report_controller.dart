import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';

class ReportController extends GetxController {
  final currentDate = DateTime.now().obs;

  final pengeluaran = 0.obs;
  final pemasukan = 0.obs;
  final saldo = 0.obs;

  final expenseByCategory = <Map<String, dynamic>>[].obs;

  final kekayaanBersih = 0.obs;
  final totalAset = 0.obs;
  final totalLiabilitas = 0.obs;

  final accountGroups = <Map<String, dynamic>>[].obs;

  // Backward-compatible getter
  int get calculatedNetWorth => totalAset.value - totalLiabilitas.value;

  String get monthLabel {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${months[currentDate.value.month]} ${currentDate.value.year}';
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void prevMonth() {
    final d = currentDate.value;
    currentDate.value = DateTime(d.year, d.month - 1);
    loadData();
  }

  void nextMonth() {
    final d = currentDate.value;
    currentDate.value = DateTime(d.year, d.month + 1);
    loadData();
  }

  Future<void> loadData() async {
    final year = currentDate.value.year;
    final month = currentDate.value.month;

    final transactions =
        await DatabaseHelper.instance.readTransactionsByMonth(year, month);
    final accounts = await DatabaseHelper.instance.readAllAccounts();
    final cats = await DatabaseHelper.instance.readAllCategories();

    // Build category color/icon map
    final Map<String, Map<String, dynamic>> catMap = {};
    for (var c in cats) {
      catMap[c['name'] as String] = c;
    }

    int totalIn = 0;
    int totalEx = 0;
    final Map<String, int> exByCat = {};

    for (var t in transactions) {
      final amt = t['amount'] as int;
      final type = t['type'] as String;

      if (type == 'pemasukan') {
        totalIn += amt;
      } else if (type == 'pengeluaran') {
        totalEx += amt;
        final cat = (t['categoryName'] as String?) ?? 'Lainnya';
        exByCat[cat] = (exByCat[cat] ?? 0) + amt;
      }
    }

    pengeluaran.value = totalEx;
    pemasukan.value = totalIn;
    saldo.value = totalIn - totalEx;

    // Build expense by category list with real colors from category table
    final fallbackColors = [
      0xFF4CAF50, 0xFF9C27B0, 0xFFFF9800, 0xFFFFEB3B, 0xFFF44336,
      0xFF2196F3, 0xFFE91E63, 0xFF00BCD4,
    ];
    final sorted = exByCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int colorIdx = 0;
    final expList = <Map<String, dynamic>>[];
    const maxCategories = 5;

    if (sorted.length > maxCategories) {
      for (int i = 0; i < maxCategories - 1; i++) {
        final e = sorted[i];
        final catData = catMap[e.key];
        final colorVal = catData != null && catData['color_val'] != null
            ? catData['color_val'] as int
            : fallbackColors[colorIdx % fallbackColors.length];
        expList.add({
          'category': e.key,
          'amount': e.value,
          'color': colorVal,
        });
        colorIdx++;
      }

      int othersAmount = 0;
      for (int i = maxCategories - 1; i < sorted.length; i++) {
        othersAmount += sorted[i].value;
      }
      
      expList.add({
        'category': 'Lain-lain',
        'amount': othersAmount,
        'color': 0xFF9E9E9E, // Grey color for Lain-lain
      });
    } else {
      for (var e in sorted) {
        final catData = catMap[e.key];
        final colorVal = catData != null && catData['color_val'] != null
            ? catData['color_val'] as int
            : fallbackColors[colorIdx % fallbackColors.length];
        expList.add({
          'category': e.key,
          'amount': e.value,
          'color': colorVal,
        });
        colorIdx++;
      }
    }
    expenseByCategory.value = expList;

    // Assets calculation
    int totalAssetCalc = 0;
    int totalLiabCalc = 0;

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var acc in accounts) {
      final balance = acc['balance'] as int;
      final type = acc['type'] as String? ?? 'Kas Pribadi';
      if (balance >= 0) {
        totalAssetCalc += balance;
      } else {
        totalLiabCalc += balance.abs();
      }

      if (!grouped.containsKey(type)) grouped[type] = [];
      grouped[type]!.add({
        'id': acc['id'],
        'name': acc['name'],
        'balance': balance,
        'type': type,
        'currency': acc['currency_code'] ?? 'IDR',
        'icon_code': acc['icon_code'],
        'icon_path': acc['icon_path'],
        'color_val': acc['color_val'] ?? 0xFFFFCA28,
        'exclude_from_total': (acc['is_excluded'] as int? ?? 0) == 1,
      });
    }

    totalAset.value = totalAssetCalc;
    totalLiabilitas.value = totalLiabCalc;
    kekayaanBersih.value = totalAssetCalc - totalLiabCalc;

    final groupList = <Map<String, dynamic>>[];
    grouped.forEach((key, value) {
      final groupTotal = value.fold(0, (s, a) => s + (a['balance'] as int));
      groupList.add({
        'groupName': key,
        'total': groupTotal,
        'accounts': value,
      });
    });
    accountGroups.value = groupList;
  }
}
