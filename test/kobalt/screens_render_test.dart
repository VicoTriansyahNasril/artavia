import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/database/transaction_store.dart';
import 'package:artavia/core/services/backup_service.dart';
import 'package:artavia/core/services/google_drive_service.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/services/pin_lock_service.dart';
import 'package:artavia/core/services/privacy_service.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/core/services/theme_service.dart';
import 'package:artavia/main.dart' show buildAppTheme;
import 'package:artavia/page/add_transaction/add_transaction_controller.dart';
import 'package:artavia/page/add_transaction/add_transaction_screen.dart';
import 'package:artavia/page/home/home_binding.dart';
import 'package:artavia/page/home/home_controller.dart';
import 'package:artavia/page/home/home_screen.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/widgets/commons/common.dart';

import 'db_test_helper.dart';

/// SC-006 / T067: every main screen renders without overflow at 100 % and
/// 150 % text on a small phone, in both themes.
Future<void> _seed() async {
  final db = DatabaseHelper.instance;
  await db.resetDatabase();
  final bca = await db.insertAccount({
    'name': 'Bank Central Asia Tabungan Utama',
    'type': 'Bank',
    'balance': 12500000,
    'icon_key': 'biaya_bank',
  });
  final gopay = await db.insertAccount(
      {'name': 'GoPay', 'type': 'Dompet Digital', 'balance': 250000});
  await db.insertAccount({
    'name': 'Kartu Kredit',
    'type': 'Kartu Kredit',
    'balance': -1750000,
    'credit_limit': 10000000,
    'due_day': 17,
  });
  final now = DateTime.now();
  for (var i = 0; i < 6; i++) {
    await db.addTransaction({
      'type': i.isEven ? 'pengeluaran' : 'pemasukan',
      'amount': 45000 * (i + 1) * 37,
      'category_id': i.isEven ? 1 : 12,
      'note': i == 0
          ? 'Makan siang bersama tim di restoran Padang dekat kantor'
          : '',
      'account_id': bca,
      'date': now.subtract(Duration(days: i)).toIso8601String(),
    });
  }
  await db.addTransaction({
    'type': 'transfer',
    'amount': 100000,
    'note': '',
    'account_id': bca,
    'destination_account_id': gopay,
    'date': now.toIso8601String(),
  });
  await db.upsertBudget(
      categoryId: 1,
      amount: 100000,
      month: PeriodService.to.active.value.month,
      year: PeriodService.to.active.value.year);
}

void main() {
  setUpAll(() async {
    await initTestDatabaseFactory();
    await initializeDateFormatting('id_ID', null);
  });

  for (final palette in [AppPalette.dark, AppPalette.light]) {
    for (final scale in [1.0, 1.5]) {
      final tag =
          '${palette.isDark ? 'dark' : 'light'} ${(scale * 100).round()}%';

      Future<void> boot(WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        AppPalette.current = palette;
        addTearDown(() => AppPalette.current = AppPalette.dark);
        await tester.runAsync(() async {
          Get.reset();
          await Get.putAsync(() => SettingsService().init());
          Get.put(PeriodService());
          Get.put(ThemeService().init());
          AppPalette.current = palette;
          Get.put(PrivacyService().init());
          Get.put(PinLockService());
          Get.put(GoogleDriveService());
          Get.put(BackupService());
          await _seed();
        });
      }

      Widget app(Widget home) => GetMaterialApp(
            theme: buildAppTheme(palette),
            home: home,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          );

      testWidgets('$tag: all four tabs render', (tester) async {
        await boot(tester);
        HomeBinding().dependencies();
        await tester.pumpWidget(app(const HomeScreen()));
        for (var i = 0; i < 4; i++) {
          Get.find<HomeController>().changePage(i);
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 150)));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull, reason: 'tab $i');
        }
      });

      testWidgets('$tag: secondary screens render', (tester) async {
        await boot(tester);
        await tester.pumpWidget(GetMaterialApp(
          theme: buildAppTheme(palette),
          getPages: route,
          home: const SizedBox(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ));
        final screens = <String, Object?>{
          budgetRoute: null,
          searchRoute: null,
          calendarRoute: null,
          categoryManagementRoute: null,
          addCategoryRoute: null,
          accountManagementRoute: null,
          addAccountRoute: null,
          recurringRoute: null,
          textSizeRoute: null,
          backupRoute: null,
          exportRoute: null,
          '$exportRoute#impor': null,
          importHistoryRoute: null,
          pinRoute: {'mode': 'setup'},
          transactionDetailRoute: {
            'id': 1,
            'type': 'pengeluaran',
            'amount': 1665000,
            'category': 'Makanan',
            'category_id': 1,
            'note': 'Makan siang bersama tim di restoran Padang dekat kantor',
            'account': 'Bank Central Asia Tabungan Utama',
            'account_id': 1,
            'date': DateTime.now(),
            'icon_key': 'makan',
            'color_val': 0xFFE07A7A,
          },
        };
        for (final e in screens.entries) {
          final name = e.key.split('#').first;
          Get.toNamed(name,
              arguments: e.key.endsWith('#impor') ? {'tab': 1} : e.value);
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 200)));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(tester.takeException(), isNull, reason: e.key);
          Get.back();
          await tester.pump(const Duration(milliseconds: 400));
        }
        // Let queued DB work finish and flush sqflite's lock-warning timer.
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 300)));
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 11));
      });

      for (final tab in AddTransactionController.tabs) {
        testWidgets('$tag: Catat $tab renders', (tester) async {
          await boot(tester);
          late AddTransactionController c;
          await tester.runAsync(() async {
            c = Get.put(AddTransactionController(initialTab: tab));
            while (c.isLoading.value) {
              await Future<void>.delayed(const Duration(milliseconds: 5));
            }
          });
          await tester.pumpWidget(app(const AddTransactionScreen()));
          for (final k in '1 2 5 0 000 000'.split(' ')) {
            c.onKey(k);
          }
          await tester.pump();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
