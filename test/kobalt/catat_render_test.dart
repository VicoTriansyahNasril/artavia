import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/main.dart' show buildAppTheme;
import 'package:artavia/page/add_transaction/add_transaction_controller.dart';
import 'package:artavia/page/add_transaction/add_transaction_screen.dart';
import 'package:artavia/page/transfer/transfer_section.dart';
import 'package:artavia/widgets/commons/common.dart';

import 'db_test_helper.dart';

void main() {
  setUpAll(initTestDatabaseFactory);

  for (final palette in [AppPalette.dark, AppPalette.light]) {
    for (final size in const [Size(360, 720), Size(412, 915)]) {
      for (final tab in AddTransactionController.tabs) {
        testWidgets(
            '${palette.isDark ? 'dark' : 'light'} ${size.width.toInt()}w '
            '$tab renders without overflow', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          AppPalette.current = palette;
          addTearDown(() => AppPalette.current = AppPalette.dark);

          late AddTransactionController c;
          await tester.runAsync(() async {
            final db = DatabaseHelper.instance;
            await db.resetDatabase();
            await db.insertAccount(
                {'name': 'BCA', 'type': 'Bank', 'balance': 20000});
            await db.insertAccount(
                {'name': 'GoPay', 'type': 'Dompet Digital', 'balance': 0});
            Get.reset();
            await Get.putAsync(() => SettingsService().init());
            Get.put(PeriodService());
            c = Get.put(AddTransactionController(initialTab: tab));
            while (c.isLoading.value) {
              await Future<void>.delayed(const Duration(milliseconds: 5));
            }
          });

          await tester.pumpWidget(GetMaterialApp(
            theme: buildAppTheme(palette),
            home: const AddTransactionScreen(),
          ));
          await tester.pump();

          for (final k in '6 0 0 000'.split(' ')) {
            c.onKey(k);
          }
          if (tab == 'Transfer') c.transfer.pickFee(2500);
          await tester.pump();

          expect(tester.takeException(), isNull);
          expect(find.bySemanticsLabel('Simpan'), findsOneWidget);
          if (tab == 'Transfer') {
            // 600.000 + 2.500 on a 20.000 balance → warning, still savable.
            final warning = find.textContaining('kurang Rp 582.500');
            await tester.scrollUntilVisible(warning, 120,
                scrollable: find
                    .descendant(
                        of: find.byType(TransferSection),
                        matching: find.byType(Scrollable))
                    .first);
            expect(warning, findsOneWidget);
            expect(c.canSave, isTrue);
          }
        });
      }
    }
  }
}
