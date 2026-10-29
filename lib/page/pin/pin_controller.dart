import 'package:get/get.dart';
import 'package:artavia/core/services/pin_lock_service.dart';

class PinController extends GetxController {
  late final bool isSetup = (Get.arguments?['mode'] ?? 'setup') == 'setup';

  /// 0 = enter (new) PIN, 1 = confirm new PIN.
  final step = 0.obs;
  final message = RxnString();
  final isError = false.obs;
  final busy = false.obs;
  String? _first;

  @override
  void onInit() {
    super.onInit();
    if (isSetup) {
      message.value = 'PIN hanya tersimpan di HP ini. Simpan cadangan di '
          'Google Drive agar data bisa dipulihkan bila lupa.';
    }
  }

  String get title {
    if (!isSetup) return 'Masukkan PIN saat ini';
    return step.value == 0
        ? 'Buat PIN ${PinLockService.newPinLength} digit'
        : 'Ulangi PIN';
  }

  /// Digits to enter: new PINs use the board length, checks use the stored.
  int get length =>
      isSetup ? PinLockService.newPinLength : PinLockService.to.pinLength;

  Future<void> onPinEntered(String pin) async {
    if (isSetup) return _setup(pin);
    busy.value = true;
    final ok = await PinLockService.to.verify(pin);
    busy.value = false;
    if (ok) {
      await PinLockService.to.disable();
      Get.back(result: true);
      return;
    }
    final wait = PinLockService.to.secondsBlocked;
    _error(wait > 0
        ? 'Coba lagi dalam $wait detik'
        : 'PIN salah. Sisa ${PinLockService.to.remainingAttempts} percobaan.');
  }

  Future<void> _setup(String pin) async {
    if (step.value == 0) {
      _first = pin;
      isError.value = false;
      message.value = null;
      step.value = 1;
      return;
    }
    if (pin != _first) {
      _first = null;
      step.value = 0;
      _error('PIN tidak sama, ulangi dari awal');
      return;
    }
    busy.value = true;
    await PinLockService.to.enable(pin);
    busy.value = false;
    Get.back(result: true);
  }

  void _error(String text) {
    isError.value = true;
    message.value = text;
  }
}
