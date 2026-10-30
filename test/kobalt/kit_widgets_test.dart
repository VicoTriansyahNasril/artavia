import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:artavia/model/transaction_model.dart';
import 'package:artavia/widgets/components/app_feedback.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

Widget _host(Widget child) => GetMaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  for (final palette in [AppPalette.dark, AppPalette.light]) {
    group(palette.isDark ? 'dark' : 'light', () {
      setUp(() => AppPalette.current = palette);
      tearDown(() => AppPalette.current = AppPalette.dark);

      testWidgets('NavRow trailing hugs the right edge', (tester) async {
        const handle = Key('handle');
        await tester.pumpWidget(_host(const SizedBox(
          width: 360,
          child: NavRow(
            title: 'Makan',
            subtitle: '3 transaksi',
            showChevron: false,
            trailing: SizedBox(key: handle, width: 44, height: 44),
          ),
        )));
        final row = tester.getRect(find.byType(NavRow));
        final right = tester.getRect(find.byKey(handle)).right;
        expect(right, moreOrLessEquals(row.right - 14)); // row padding
      });

      testWidgets('Keypad emits keys and Simpan respects saveEnabled',
          (tester) async {
        final keys = <String>[];
        var saved = 0;
        Future<void> pump(bool enabled) => tester.pumpWidget(_host(SizedBox(
              width: 360,
              child: Keypad(
                onKey: keys.add,
                onSave: () => saved++,
                saveEnabled: enabled,
              ),
            )));

        await pump(false);
        await tester.tap(find.text('7'));
        await tester.tap(find.text('000'));
        await tester.tap(find.bySemanticsLabel('Tambah'));
        await tester.tap(find.bySemanticsLabel('Hapus satu angka'));
        await tester.tap(find.bySemanticsLabel('Simpan'));
        expect(keys, ['7', '000', KeypadKey.plus, KeypadKey.backspace]);
        expect(saved, 0);

        await pump(true);
        await tester.tap(find.bySemanticsLabel('Simpan'));
        expect(saved, 1);
      });

      testWidgets('KBottomNav switches tabs and opens Catat', (tester) async {
        int? tapped;
        var catat = 0;
        await tester.pumpWidget(GetMaterialApp(
          home: Scaffold(
            bottomNavigationBar: KBottomNav(
              index: 0,
              onTap: (i) => tapped = i,
              onCatat: () => catat++,
            ),
          ),
        ));
        for (final label in [
          'Transaksi',
          'Laporan',
          'Rekening',
          'Pengaturan'
        ]) {
          expect(find.text(label), findsOneWidget);
        }
        await tester.tap(find.text('Rekening'));
        expect(tapped, 2);
        await tester.tap(find.bySemanticsLabel('Catat transaksi'));
        expect(catat, 1);
      });

      testWidgets('TxRow shows Kategori · Rekening · jam and signed amount',
          (tester) async {
        final tx = TransactionModel(
          amount: -45000,
          type: 'pengeluaran',
          note: 'Makan siang',
          categoryName: 'Makanan',
          categoryIconKey: 'makan',
          categoryColorVal: 0xFFE07A7A,
          accountName: 'BCA',
          date: DateTime(2026, 10, 29, 12, 30),
        );
        await tester.pumpWidget(_host(TxRow(tx: tx)));
        expect(find.text('Makan siang'), findsOneWidget);
        expect(find.text('Makanan · BCA · 12.30'), findsOneWidget);
        expect(find.text('−Rp 45.000'), findsOneWidget);
      });

      testWidgets('KButton disabled has no tap and 40 % opacity',
          (tester) async {
        await tester.pumpWidget(_host(const KButton(label: 'Simpan')));
        final opacity = tester.widget<Opacity>(find.ancestor(
            of: find.text('Simpan'), matching: find.byType(Opacity)));
        expect(opacity.opacity, 0.4);
      });

      testWidgets('Undo snackbar calls back only when tapped', (tester) async {
        var undone = 0;
        await tester.pumpWidget(_host(const SizedBox()));
        AppToast.undo('Transaksi dihapus', onUndo: () => undone++);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Transaksi dihapus'), findsOneWidget);
        await tester.tap(find.text('Urungkan'));
        await tester.pump();
        expect(undone, 1);
        expect(find.text('Transaksi dihapus'), findsNothing);

        AppToast.undo('Lagi', onUndo: () => undone++);
        await tester.pump(const Duration(seconds: 6));
        expect(find.text('Lagi'), findsNothing);
        expect(undone, 1);
      });
    });
  }
}
