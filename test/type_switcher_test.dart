import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artavia/widgets/components/type_switcher.dart';

void main() {
  for (final width in [320.0, 412.0, 600.0]) {
    testWidgets('segments are equal and centred at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TransactionTypeSwitcher(
                selected: 'Pengeluaran', onChanged: (_) {}),
          ),
        ),
      ));

      expect(tester.takeException(), isNull); // no overflow
      final rects = TransactionTypeSwitcher.types
          .map((t) => tester.getRect(find.ancestor(
              of: find.text(t), matching: find.byType(AnimatedContainer))))
          .toList();
      expect(rects[0].width, closeTo(rects[1].width, 0.5));
      expect(rects[1].width, closeTo(rects[2].width, 0.5));
      // The middle segment sits exactly on the screen's centre line.
      expect(rects[1].center.dx, closeTo(width / 2, 0.5));
    });
  }
}
