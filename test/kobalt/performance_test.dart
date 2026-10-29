import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/core/utils/finance_calc.dart';
import 'package:artavia/page/home/home_controller.dart';
import 'package:artavia/page/report/report_controller.dart';

import 'db_test_helper.dart';

/// NFR-003 / T083: with 5 000 transactions the data work behind a tab
/// switch or a post-save refresh stays well under 300 ms (desktop VM; a
/// mid-range phone is a few times slower, so the bound here is 150 ms).
void main() {
  setUpAll(() async {
    await initTestDatabaseFactory();
    Get.testMode = true;
  });

  test('5 000 transactions: home + report refresh is fast', () async {
    final db = DatabaseHelper.instance;
    await db.resetDatabase();
    final acc = await db
        .insertAccount({'name': 'BCA', 'type': 'Bank', 'balance': 100000000});
    final raw = await db.database;
    final now = DateTime.now();
    final batch = raw.batch();
    for (var i = 0; i < 5000; i++) {
      batch.insert('transactions', {
        'type': i % 5 == 0 ? 'pemasukan' : 'pengeluaran',
        'amount': 10000 + i,
        'category_id': i % 5 == 0 ? 12 : 1 + i % 10,
        'note': 'Transaksi $i',
        'account_id': acc,
        'date': now.subtract(Duration(hours: i * 2)).toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    }
    await batch.commit(noResult: true);

    Get.reset();
    await Get.putAsync(() => SettingsService().init());
    Get.put(PeriodService());
    final home = HomeController();
    final report = ReportController();

    // Warm up (first query compiles statements).
    await home.loadData();
    await report.loadData();

    final sw = Stopwatch()..start();
    await home.loadData();
    final homeMs = sw.elapsedMilliseconds;
    sw.reset();
    await report.loadData();
    final reportMs = sw.elapsedMilliseconds;
    sw.reset();
    final all = await db.readAllTransactions();
    rankCategories(
        await db.readAllCategories(), await db.categoryUsage('pengeluaran'));
    final allMs = sw.elapsedMilliseconds;

    // ignore: avoid_print
    print('home ${homeMs}ms · laporan ${reportMs}ms · '
        'semua+ranking ${allMs}ms (${all.length} transaksi)');
    expect(all.length, 5000);
    expect(homeMs, lessThan(150));
    expect(reportMs, lessThan(150));
  });
}
