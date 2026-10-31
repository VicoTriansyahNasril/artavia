import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:artavia/core/services/privacy_service.dart';
import 'package:artavia/core/utils/currency_format.dart';

class _Amount extends StatelessWidget {
  const _Amount();

  static var builds = 0;

  @override
  Widget build(BuildContext context) {
    PrivacyService.watch(context);
    builds++;
    return Text(CurrencyService.to.money(125000));
  }
}

class _Static extends StatelessWidget {
  const _Static();

  static var builds = 0;

  @override
  Widget build(BuildContext context) {
    builds++;
    return const Text('label');
  }
}

void main() {
  testWidgets('eye toggle repaints watchers only, no app-wide rebuild',
      (tester) async {
    Get.testMode = true;
    final privacy = Get.put(PrivacyService());
    addTearDown(() {
      CurrencyService.to.masked = false;
      Get.delete<PrivacyService>(force: true);
    });

    await tester.pumpWidget(GetMaterialApp(
      builder: (context, child) => Obx(() => PrivacyScope(
            masked: PrivacyService.to.masked.value,
            child: child!,
          )),
      home: const Scaffold(body: Column(children: [_Amount(), _Static()])),
    ));
    expect(find.text('Rp 125.000'), findsOneWidget);
    final amountBuilds = _Amount.builds, staticBuilds = _Static.builds;

    privacy.toggle();
    await tester.pump();
    expect(find.text('Rp ••••••'), findsOneWidget);
    expect(_Amount.builds, amountBuilds + 1);
    expect(_Static.builds, staticBuilds, reason: 'non-amount widgets stay');

    privacy.toggle();
    await tester.pump();
    expect(find.text('Rp 125.000'), findsOneWidget);
  });
}
