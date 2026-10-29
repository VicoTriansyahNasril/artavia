import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/services/notification_service.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/services/pin_lock_service.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/core/utils/data_refresh.dart';
import 'package:artavia/page/pin/pin_pad.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// Covers the whole app while [PinLockService.isLocked] is true.
class LockOverlay extends StatelessWidget {
  final Widget child;

  const LockOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Stack(
          children: [
            child,
            if (PinLockService.to.isLocked.value) const _UnlockScreen(),
          ],
        ));
  }
}

class _UnlockScreen extends StatefulWidget {
  const _UnlockScreen();

  @override
  State<_UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<_UnlockScreen> {
  String? _message;
  bool _busy = false;

  PinLockService get _service => PinLockService.to;

  @override
  void initState() {
    super.initState();
    // Offer the fingerprint prompt right away when it is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_service.canUseBiometrics.value) _service.unlockWithBiometrics();
    });
  }

  Future<void> _check(String pin) async {
    if (_service.secondsBlocked > 0) {
      setState(
          () => _message = 'Coba lagi dalam ${_service.secondsBlocked} detik');
      return;
    }
    setState(() => _busy = true);
    final ok = await _service.verify(pin);
    if (!mounted) return;
    if (ok) {
      _service.unlock();
      return;
    }
    final wait = _service.secondsBlocked;
    final left = _service.remainingAttempts;
    setState(() {
      _busy = false;
      _message = wait > 0
          ? 'Terlalu banyak percobaan. Coba lagi dalam $wait detik'
          : 'PIN salah. Sisa $left percobaan.';
    });
  }

  /// "Lupa PIN?" panel: 0 = hidden, 1 = explanation, 2 = final confirm.
  /// Drawn inline because this screen sits above the navigator, where
  /// sheets and dialogs would open underneath it.
  int _forgotStep = 0;

  Future<void> _resetAndRestore() async {
    await NotificationService.to.cancel();
    await DatabaseHelper.instance.resetDatabase();
    await SettingsService.to.reload();
    PeriodService.to.resetToToday();
    _service.unlock();
    refreshAllGlobalData();
    Get.toNamed(backupRoute);
  }

  Widget _forgotPanel() {
    final confirm = _forgotStep == 2;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GlassCard(
        level: GlassLevel.thick,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(confirm ? LucideIcons.triangleAlert : LucideIcons.keyRound,
                size: 32, color: confirm ? colorDanger : colorAccent),
            const SizedBox(height: 12),
            Text(confirm ? 'Hapus semua data di HP?' : 'Lupa PIN?',
                textAlign: TextAlign.center,
                style: AppText.title3.copyWith(color: colorText)),
            const SizedBox(height: 8),
            Text(
                confirm
                    ? 'Data di HP ini akan dihapus. Setelah itu kamu bisa '
                        'memulihkan cadangan dari Google Drive.'
                    : 'PIN tidak bisa dipulihkan karena hanya tersimpan di HP '
                        'ini. Kamu bisa menghapus data di HP lalu memulihkannya '
                        'dari cadangan Google Drive. Transaksi setelah cadangan '
                        'terakhir akan hilang.',
                textAlign: TextAlign.center,
                style: AppText.bodySmall.onGlass),
            const SizedBox(height: 18),
            KButton.danger(
              label: confirm ? 'Ya, hapus data' : 'Hapus data & pulihkan',
              onPressed: confirm
                  ? _resetAndRestore
                  : () => setState(() => _forgotStep = 2),
            ),
            const SizedBox(height: 8),
            KButton.text(
              label: 'Kembali ke PIN',
              onPressed: () => setState(() => _forgotStep = 0),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colorBackground,
        body: Stack(
          children: [
            const AmbientOrb(centered: true),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: _forgotStep > 0
                      ? _forgotPanel()
                      : Obx(() => PinPad(
                            title: 'Masukkan PIN',
                            length: _service.pinLength,
                            message: _message,
                            isError: _message != null,
                            busy: _busy,
                            onCompleted: _check,
                            onBiometric: _service.canUseBiometrics.value
                                ? _service.unlockWithBiometrics
                                : null,
                            onForgot: () => setState(() => _forgotStep = 1),
                          )),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
