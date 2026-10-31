import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:artavia/core/services/settings_service.dart';

/// PBKDF2-HMAC-SHA256 with 600k iterations (security-standard.md, passwords).
Future<String> hashPin(String pin, List<int> salt) async {
  final algorithm = Pbkdf2.hmacSha256(iterations: 600000, bits: 256);
  final key = await algorithm.deriveKeyFromPassword(password: pin, nonce: salt);
  return base64Encode(await key.extractBytes());
}

Future<String> _hashInIsolate(Map<String, Object> args) =>
    hashPin(args['pin'] as String, args['salt'] as List<int>);

List<int> newPinSalt() {
  final random = Random.secure();
  return List<int>.generate(16, (_) => random.nextInt(256));
}

/// Constant-time comparison so verification time doesn't leak the hash.
bool hashesEqual(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}

/// App lock (FR-031d): locks at startup and when the app returns from the
/// background after [_grace] (so share sheets/pickers don't trigger it).
class PinLockService extends GetxService with WidgetsBindingObserver {
  static PinLockService get to => Get.find();

  static const _grace = Duration(seconds: 10);
  static const maxAttempts = 5;

  /// First cooldown; doubles on every further lockout up to [maxCooldown].
  static const cooldown = Duration(seconds: 30);
  static const maxCooldown = Duration(minutes: 15);

  static const keyPinLength = 'pin_length';

  // Wrong-PIN state lives in settings, so killing the app doesn't reset it.
  static const keyPinFailed = 'pin_failed';
  static const keyPinLockouts = 'pin_lockouts';
  static const keyPinBlockedUntil = 'pin_blocked_until';

  /// New PINs are 6 digits (board); PINs made before v12 keep 4.
  static const newPinLength = 6;

  final isLocked = false.obs;

  /// Fingerprint / face unlock is possible on this device (FR-029).
  final canUseBiometrics = false.obs;
  final _auth = LocalAuthentication();
  DateTime? _pausedAt;

  SettingsService get _s => SettingsService.to;
  int get _failed => int.tryParse(_s.get(keyPinFailed) ?? '') ?? 0;
  int get _lockouts => int.tryParse(_s.get(keyPinLockouts) ?? '') ?? 0;
  DateTime? get _blockedUntil =>
      DateTime.tryParse(_s.get(keyPinBlockedUntil) ?? '');

  bool get enabled =>
      SettingsService.to.appLock &&
      SettingsService.to.get(SettingsService.keyPinHash) != null;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    isLocked.value = enabled;
    _secureScreen(enabled);
    _checkBiometrics();
  }

  static const _secure = MethodChannel('artavia/secure_screen');

  /// Re-applies FLAG_SECURE after settings were replaced (reset/restore).
  Future<void> syncSecureScreen() => _secureScreen(enabled);

  /// Android FLAG_SECURE while the lock is on: no content in Recents, no
  /// screenshots. No-op elsewhere.
  Future<void> _secureScreen(bool on) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _secure.invokeMethod('set', on);
    } on MissingPluginException {
      // Tests / hosts without the channel.
    } on PlatformException catch (_) {}
  }

  Future<void> _checkBiometrics() async {
    try {
      canUseBiometrics.value = await _auth.isDeviceSupported() &&
          await _auth.canCheckBiometrics &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      canUseBiometrics.value = false;
    }
  }

  /// Digits of the stored PIN.
  int get pinLength =>
      int.tryParse(SettingsService.to.get(keyPinLength) ?? '') ?? 4;

  /// Wrong tries left before the cooldown starts.
  int get remainingAttempts => maxAttempts - _failed;

  /// Unlocks with fingerprint / face; returns true on success.
  Future<bool> unlockWithBiometrics() async {
    if (!enabled || !canUseBiometrics.value) return false;
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Buka Artavia',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (ok) {
        await _resetAttempts();
        unlock();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final pausedAt = _pausedAt;
      _pausedAt = null;
      if (enabled &&
          pausedAt != null &&
          DateTime.now().difference(pausedAt) >= _grace) {
        isLocked.value = true;
      }
    }
  }

  /// Seconds the user must still wait after too many wrong PINs (0 = none).
  int get secondsBlocked {
    final until = _blockedUntil;
    if (until == null) return 0;
    final left = until.difference(DateTime.now()).inSeconds;
    return left > 0 ? left + 1 : 0;
  }

  Future<bool> verify(String pin) async {
    if (secondsBlocked > 0) return false;
    final salt = SettingsService.to.get(SettingsService.keyPinSalt);
    final stored = SettingsService.to.get(SettingsService.keyPinHash);
    if (salt == null || stored == null) return false;
    final hash =
        await compute(_hashInIsolate, {'pin': pin, 'salt': base64Decode(salt)});
    if (hashesEqual(hash, stored)) {
      await _resetAttempts();
      return true;
    }
    final failed = _failed + 1;
    if (failed < maxAttempts) {
      await _s.set(keyPinFailed, '$failed');
      return false;
    }
    final wait = cooldown * (1 << _lockouts.clamp(0, 10));
    await _s.set(keyPinFailed, '0');
    await _s.set(keyPinLockouts, '${_lockouts + 1}');
    await _s.set(
        keyPinBlockedUntil,
        DateTime.now()
            .add(wait > maxCooldown ? maxCooldown : wait)
            .toIso8601String());
    return false;
  }

  Future<void> _resetAttempts() async {
    await _s.remove(keyPinFailed);
    await _s.remove(keyPinLockouts);
    await _s.remove(keyPinBlockedUntil);
  }

  /// "30 detik" / "4 menit" for the lockout message.
  static String waitLabel(int seconds) =>
      seconds < 60 ? '$seconds detik' : '${(seconds / 60).ceil()} menit';

  Future<void> enable(String pin) async {
    final salt = newPinSalt();
    final hash = await compute(_hashInIsolate, {'pin': pin, 'salt': salt});
    final settings = SettingsService.to;
    await settings.set(SettingsService.keyPinSalt, base64Encode(salt));
    await settings.set(SettingsService.keyPinHash, hash);
    await settings.set(keyPinLength, '${pin.length}');
    await settings.set(SettingsService.keyAppLock, 'true');
    await _secureScreen(true);
  }

  Future<void> disable() async {
    final settings = SettingsService.to;
    await settings.set(SettingsService.keyAppLock, 'false');
    await settings.remove(SettingsService.keyPinSalt);
    await settings.remove(SettingsService.keyPinHash);
    await settings.remove(keyPinLength);
    await _resetAttempts();
    await _secureScreen(false);
    isLocked.value = false;
  }

  void unlock() => isLocked.value = false;
}
