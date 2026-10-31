import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:artavia/page/splash/splash_screen.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

void main() {
  testWidgets('KAmountField types with the in-app keypad, not the keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final values = <int>[];
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: KAmountField(label: 'Saldo', value: 0, onChanged: values.add),
      ),
    ));
    expect(find.byType(EditableText), findsNothing);

    await tester.tap(find.byType(KAmountField));
    await tester.pumpAndSettle();
    expect(find.byType(Keypad), findsOneWidget);

    await tester.tap(find.text('5'));
    await tester.tap(find.text('000'));
    await tester.tap(find.bySemanticsLabel('Tambah'));
    await tester.tap(find.text('2'));
    await tester.pump();
    expect(find.text('5.000 + 2'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Selesai'));
    await tester.pumpAndSettle();

    expect(values, [5002]);
    expect(find.text('5.002'), findsOneWidget);
  });

  testWidgets('splash animates the gold bar and the progress bar',
      (tester) async {
    await tester.pumpWidget(const SplashApp());
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Artavia'), findsOneWidget);
    expect(tester.hasRunningAnimations, isTrue);
    expect(tester.takeException(), isNull);
  });
}
