import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
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
  static const cooldown = Duration(seconds: 30);

  final isLocked = false.obs;
  DateTime? _pausedAt;
  int _failed = 0;
  DateTime? _blockedUntil;

  bool get enabled =>
      SettingsService.to.appLock &&
      SettingsService.to.get(SettingsService.keyPinHash) != null;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    isLocked.value = enabled;
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
      _failed = 0;
      _blockedUntil = null;
      return true;
    }
    _failed++;
    if (_failed >= maxAttempts) {
      _failed = 0;
      _blockedUntil = DateTime.now().add(cooldown);
    }
    return false;
  }

  Future<void> enable(String pin) async {
    final salt = newPinSalt();
    final hash = await compute(_hashInIsolate, {'pin': pin, 'salt': salt});
    final settings = SettingsService.to;
    await settings.set(SettingsService.keyPinSalt, base64Encode(salt));
    await settings.set(SettingsService.keyPinHash, hash);
    await settings.set(SettingsService.keyAppLock, 'true');
  }

  Future<void> disable() async {
    final settings = SettingsService.to;
    await settings.set(SettingsService.keyAppLock, 'false');
    await settings.remove(SettingsService.keyPinSalt);
    await settings.remove(SettingsService.keyPinHash);
    isLocked.value = false;
  }

  void unlock() => isLocked.value = false;
}
