import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/services/pin_lock_service.dart';
import 'package:artavia/page/pin/pin_pad.dart';
import 'package:artavia/widgets/commons/common.dart';

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

  Future<void> _check(String pin) async {
    final service = PinLockService.to;
    if (service.secondsBlocked > 0) {
      setState(
          () => _message = 'Coba lagi dalam ${service.secondsBlocked} detik');
      return;
    }
    setState(() => _busy = true);
    final ok = await service.verify(pin);
    if (!mounted) return;
    if (ok) {
      service.unlock();
      return;
    }
    final wait = service.secondsBlocked;
    setState(() {
      _busy = false;
      _message = wait > 0
          ? 'Terlalu banyak percobaan. Coba lagi dalam $wait detik'
          : 'PIN salah';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colorBackground,
        body: SafeArea(
          child: Center(
            child: PinPad(
              title: 'Masukkan PIN',
              message: _message,
              isError: _message != null,
              busy: _busy,
              onCompleted: _check,
            ),
          ),
        ),
      ),
    );
  }
}
