import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:artavia/core/services/pin_lock_service.dart';
import 'package:artavia/core/services/settings_service.dart';

import 'db_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initTestDatabaseFactory();
    Get.testMode = true;
    await Get.putAsync(() => SettingsService().init());
  });

  test('wrong-PIN lockout survives an app restart and escalates', () async {
    final s = SettingsService.to;
    final salt = newPinSalt();
    await s.set(SettingsService.keyPinSalt, base64Encode(salt));
    await s.set(SettingsService.keyPinHash, await hashPin('123456', salt));
    await s.set(SettingsService.keyAppLock, 'true');
    // Four wrong tries already made before the app was killed.
    await s.set(PinLockService.keyPinFailed, '4');
    await s.set(PinLockService.keyPinLockouts, '1');

    var pin = Get.put(PinLockService());
    expect(pin.remainingAttempts, 1);
    expect(await pin.verify('000000'), isFalse);
    // Second lockout: 30 s × 2.
    expect(pin.secondsBlocked, inInclusiveRange(59, 61));

    // "Restart": a fresh service reads the same settings.
    Get.delete<PinLockService>(force: true);
    pin = Get.put(PinLockService());
    expect(pin.secondsBlocked, greaterThan(0));
    expect(await pin.verify('123456'), isFalse, reason: 'still blocked');

    await s.remove(PinLockService.keyPinBlockedUntil);
    expect(await pin.verify('123456'), isTrue);
    expect(s.get(PinLockService.keyPinLockouts), isNull);
    expect(pin.remainingAttempts, PinLockService.maxAttempts);
  });

  test('wait label switches to minutes', () {
    expect(PinLockService.waitLabel(45), '45 detik');
    expect(PinLockService.waitLabel(61), '2 menit');
    expect(PinLockService.waitLabel(900), '15 menit');
  });
}
