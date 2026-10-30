import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/main.dart' show buildAppTheme;
import 'package:artavia/page/add_transaction/add_transaction_controller.dart';
import 'package:artavia/page/add_transaction/add_transaction_screen.dart';
import 'package:artavia/widgets/commons/common.dart';

import 'db_test_helper.dart';

/// Typing after scrolling far down the category grid must keep the amount
/// in view: pinned above the grid on normal screens, scrolled back up on
/// very short ones.
void main() {
  setUpAll(initTestDatabaseFactory);

  for (final (size, scale) in const [
    (Size(360, 720), 1.0),
    (Size(360, 720), 1.5),
    (Size(360, 640), 1.0),
  ]) {
    testWidgets(
        '${size.width.toInt()}×${size.height.toInt()} ×$scale: '
        'amount stays visible while typing after scrolling', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      late AddTransactionController c;
      await tester.runAsync(() async {
        final db = DatabaseHelper.instance;
        await db.resetDatabase();
        await db.insertAccount({'name': 'BCA', 'type': 'Bank', 'balance': 0});
        Get.reset();
        await Get.putAsync(() => SettingsService().init());
        Get.put(PeriodService());
        c = Get.put(AddTransactionController());
        while (c.isLoading.value) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await tester.pumpWidget(GetMaterialApp(
        theme: buildAppTheme(AppPalette.dark),
        home: const AddTransactionScreen(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ));
      await tester.pump();

      c.selectCategory(c.categories.first['id'] as int);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Kategori baru').hitTestable(),
          findsOneWidget,
          reason: 'scrolled to the end of the grid');

      for (final k in '4 5 000'.split(' ')) {
        c.onKey(k);
      }
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AmountDisplay).hitTestable(), findsOneWidget);
      expect(find.text('45.000'), findsOneWidget);
    });
  }
}
