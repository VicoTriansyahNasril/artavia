import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/services/backup_codec.dart';
import 'package:artavia/core/services/google_drive_service.dart';
import 'package:artavia/core/services/pin_lock_service.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/core/utils/data_refresh.dart';

enum BackupPhase { idle, running, failed }

/// One backup on Drive, read from `appProperties` (no download needed).
class BackupEntry {
  final String id;
  final DateTime createdAt;
  final String device;
  final int txCount;
  final int accountCount;
  final int sizeBytes;
  final bool locked;
  final String? hint;

  /// Pre-v12 `artavia_backup.db` in My Drive.
  final bool legacy;

  const BackupEntry({
    required this.id,
    required this.createdAt,
    required this.device,
    required this.txCount,
    required this.accountCount,
    required this.sizeBytes,
    required this.locked,
    this.hint,
    this.legacy = false,
  });
}

class BackupFailure implements Exception {
  final String message;
  const BackupFailure(this.message);
  @override
  String toString() => message;
}

Future<List<int>> _deriveInIsolate(Map<String, Object> a) =>
    BackupCodec.deriveKey(a['password'] as String, a['salt'] as List<int>,
        iterations: a['iter'] as int);

/// Encrypted Google Drive backups (US8, research R10).
///
/// Files `artavia-<yyyyMMdd-HHmm>.artv` live in the hidden appData folder;
/// the newest [keep] are kept. With a password, the derived AES key (never
/// the password) is kept on this device so daily auto-backups can encrypt;
/// it is stripped from every uploaded copy.
class BackupService extends GetxService with WidgetsBindingObserver {
  static BackupService get to => Get.find();

  static const keep = 5;
  static const keyBackupKey = 'backup_key';
  static const keyBackupSalt = 'backup_salt';
  static const _legacyName = 'artavia_backup.db';

  final phase = BackupPhase.idle.obs;
  final progress = 0.0.obs;
  final history = <BackupEntry>[].obs;
  final lastError = RxnString();
  bool _cancelled = false;

  SettingsService get _s => SettingsService.to;
  GoogleDriveService get _drive => GoogleDriveService.to;

  bool get isLocked =>
      _s.backupLocked &&
      _s.get(keyBackupKey) != null &&
      _s.get(keyBackupSalt) != null;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    ever(_drive.isConnected, (bool on) async {
      if (on) {
        await refreshHistory();
        await _offerRestoreIfEmpty();
        await maybeAutoBackup();
      } else {
        history.clear();
      }
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) maybeAutoBackup();
  }

  // ─── Password ────────────────────────────────────────────────────────────

  /// Turns encryption on (with [password]) or off (null). Only the hint and
  /// the derived key are stored.
  Future<void> setPassword(String? password, {String? hint}) async {
    if (password == null) {
      await _s.set(SettingsService.keyBackupLocked, 'false');
      await _s.remove(keyBackupKey);
      await _s.remove(keyBackupSalt);
      await _s.remove(SettingsService.keyBackupHint);
      return;
    }
    final salt = BackupCodec.newSalt();
    final key = await compute(_deriveInIsolate, {
      'password': password,
      'salt': salt,
      'iter': BackupCodec.defaultIterations,
    });
    await _rememberKey(key, salt);
    final h = hint?.trim() ?? '';
    if (h.isEmpty) {
      await _s.remove(SettingsService.keyBackupHint);
    } else {
      await _s.set(SettingsService.keyBackupHint, h);
    }
  }

  Future<void> _rememberKey(List<int> key, List<int> salt) async {
    await _s.set(keyBackupKey, base64Encode(key));
    await _s.set(keyBackupSalt, base64Encode(salt));
    await _s.set(SettingsService.keyBackupLocked, 'true');
  }

  // ─── Backup ──────────────────────────────────────────────────────────────

  void cancel() => _cancelled = true;

  /// Uploads a new backup. [auto] never shows the consent screen.
  Future<BackupEntry?> backupNow({bool auto = false}) async {
    if (phase.value == BackupPhase.running) return null;
    _cancelled = false;
    phase.value = BackupPhase.running;
    progress.value = 0.02;
    lastError.value = null;
    String? uploadedId;
    try {
      final api = await _drive.api(prompt: !auto);
      if (api == null) {
        throw const BackupFailure('Google Drive belum terhubung');
      }
      final (bytes, txCount, accountCount) = await _snapshot();
      progress.value = 0.2;
      _checkCancel();

      final now = DateTime.now();
      final locked = isLocked;
      final header = BackupHeader(
        createdAt: now,
        device: Platform.operatingSystem == 'ios' ? 'iPhone' : 'Android',
        txCount: txCount,
        accountCount: accountCount,
        dbVersion: DatabaseHelper.dbVersion,
        locked: locked,
        hint: locked ? _s.backupHint : null,
        salt: locked ? base64Decode(_s.get(keyBackupSalt)!) : null,
      );
      final file = await BackupCodec.encode(bytes, header,
          key: locked ? base64Decode(_s.get(keyBackupKey)!) : null);
      progress.value = 0.3;
      _checkCancel();

      final meta = drive.File()
        ..name = 'artavia-${DateFormat('yyyyMMdd-HHmm').format(now)}.artv'
        ..parents = ['appDataFolder']
        ..appProperties = {
          'createdAt': now.toIso8601String(),
          'device': header.device,
          'txCount': '$txCount',
          'accountCount': '$accountCount',
          'locked': '$locked',
          if (header.hint != null) 'hint': header.hint!,
        };
      final created = await api.files.create(meta,
          uploadMedia: drive.Media(_withProgress(file), file.length));
      uploadedId = created.id;
      if (_cancelled) {
        if (uploadedId != null) await api.files.delete(uploadedId);
        phase.value = BackupPhase.idle;
        return null;
      }
      progress.value = 0.97;
      await _prune(api);

      await _s.set(SettingsService.keyLastBackupAt, now.toIso8601String());
      await _s.set(SettingsService.keyLastBackupBytes, '${file.length}');
      await _s.set(SettingsService.keyLastBackupTx, '$txCount');
      await refreshHistory();
      progress.value = 1;
      phase.value = BackupPhase.idle;
      return history.firstWhereOrNull((e) => e.id == uploadedId);
    } on _Cancelled {
      phase.value = BackupPhase.idle;
      return null;
    } catch (e) {
      lastError.value = e is BackupFailure
          ? e.message
          : 'Tidak bisa terhubung ke Google Drive';
      phase.value = BackupPhase.failed;
      rethrow;
    }
  }

  void _checkCancel() {
    if (_cancelled) throw const _Cancelled();
  }

  Stream<List<int>> _withProgress(Uint8List bytes) async* {
    const chunk = 64 * 1024;
    for (var i = 0; i < bytes.length; i += chunk) {
      final end = i + chunk < bytes.length ? i + chunk : bytes.length;
      yield bytes.sublist(i, end);
      progress.value = 0.3 + 0.65 * end / bytes.length;
    }
  }

  /// Consistent copy of the DB without the locally kept backup key.
  Future<(Uint8List, int, int)> _snapshot() async {
    final tmpDir = await getTemporaryDirectory();
    final copy = File(p.join(tmpDir.path, 'artavia-snapshot.db'));
    if (copy.existsSync()) copy.deleteSync();
    await File(await DatabaseHelper.instance.databaseFilePath())
        .copy(copy.path);
    final db = await openDatabase(copy.path, singleInstance: false);
    try {
      await db.delete('settings',
          where: 'key IN (?, ?)', whereArgs: [keyBackupKey, keyBackupSalt]);
      final tx = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM transactions')) ??
          0;
      final acc = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM accounts')) ??
          0;
      await db.close();
      final bytes = await copy.readAsBytes();
      return (bytes, tx, acc);
    } finally {
      if (db.isOpen) await db.close();
      if (copy.existsSync()) copy.deleteSync();
    }
  }

  Future<void> _prune(drive.DriveApi api) async {
    final files = await _listFiles(api);
    for (final f in files.skip(keep)) {
      await api.files.delete(f.id!);
    }
  }

  Future<List<drive.File>> _listFiles(drive.DriveApi api) async {
    final res = await api.files.list(
      spaces: 'appDataFolder',
      q: "name contains '.artv' and trashed = false",
      orderBy: 'createdTime desc',
      $fields: 'files(id,name,size,createdTime,appProperties)',
    );
    return res.files ?? [];
  }

  // ─── History ─────────────────────────────────────────────────────────────

  Future<List<BackupEntry>> refreshHistory() async {
    final api = await _drive.api();
    if (api == null) return history;
    try {
      final entries = [
        for (final f in await _listFiles(api)) _entry(f),
      ];
      final legacy = await api.files.list(
        q: "name = '$_legacyName' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id,size,modifiedTime)',
      );
      for (final f in legacy.files ?? <drive.File>[]) {
        entries.add(BackupEntry(
          id: f.id!,
          createdAt: f.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0),
          device: 'Versi lama',
          txCount: 0,
          accountCount: 0,
          sizeBytes: int.tryParse(f.size ?? '') ?? 0,
          locked: false,
          legacy: true,
        ));
      }
      history.value = entries;
    } catch (_) {
      // Offline: keep the last known list.
    }
    return history;
  }

  BackupEntry _entry(drive.File f) {
    final a = f.appProperties ?? const {};
    return BackupEntry(
      id: f.id!,
      createdAt: DateTime.tryParse(a['createdAt'] ?? '') ??
          f.createdTime ??
          DateTime.fromMillisecondsSinceEpoch(0),
      device: a['device'] ?? '—',
      txCount: int.tryParse(a['txCount'] ?? '') ?? 0,
      accountCount: int.tryParse(a['accountCount'] ?? '') ?? 0,
      sizeBytes: int.tryParse(f.size ?? '') ?? 0,
      locked: a['locked'] == 'true',
      hint: a['hint'],
    );
  }

  // ─── Restore ─────────────────────────────────────────────────────────────

  /// Replaces local data with [entry]. Throws [WrongPassword] (uniform) for
  /// a bad password or a damaged file.
  Future<void> restore(BackupEntry entry, {String? password}) async {
    final api = await _drive.api(prompt: true);
    if (api == null) throw const BackupFailure('Google Drive belum terhubung');
    final media = await api.files.get(entry.id,
        downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    final buffer = BytesBuilder(copy: false);
    await for (final chunk in media.stream) {
      buffer.add(chunk);
    }
    final raw = buffer.toBytes();

    final header = BackupCodec.readHeader(raw);
    List<int>? key;
    if (header.locked) {
      if (password == null || password.isEmpty) throw const WrongPassword();
      key = await compute(_deriveInIsolate, {
        'password': password,
        'salt': header.salt!,
        'iter': header.iterations,
      });
    }
    final decoded = await BackupCodec.decode(raw, key: key);

    final tmpDir = await getTemporaryDirectory();
    final tmp = File(p.join(tmpDir.path, 'artavia-restore.db'));
    await tmp.writeAsBytes(decoded.database, flush: true);
    try {
      final check = await openDatabase(tmp.path, singleInstance: false);
      final ok =
          (await check.rawQuery('PRAGMA integrity_check')).first.values.first;
      await check.close();
      if (ok != 'ok') throw const WrongPassword();

      await DatabaseHelper.instance.replaceDatabaseWith(tmp);
    } finally {
      if (tmp.existsSync()) tmp.deleteSync();
    }

    await _s.reload();
    // Keep encrypting future backups with the same password.
    if (header.locked && key != null) {
      await _rememberKey(key, header.salt!);
      if (header.hint != null) {
        await _s.set(SettingsService.keyBackupHint, header.hint!);
      }
    }
    PeriodService.to.resetToToday();
    await PinLockService.to.syncSecureScreen();
    refreshAllGlobalData();
  }

  // ─── Auto ────────────────────────────────────────────────────────────────

  /// Runs on start/resume (no background scheduler): enabled, connected,
  /// last success > 24 h, and Wi-Fi when "Hanya lewat Wi-Fi" is on.
  /// Failures go to [onAutoBackupFailed] ("Cadangan gagal" toast).
  Future<void> maybeAutoBackup() async {
    if (!_drive.isConnected.value || !_s.backupAuto) return;
    if (phase.value == BackupPhase.running) return;
    final last = _s.lastBackupAt;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(hours: 24)) {
      return;
    }
    if (_s.backupWifiOnly) {
      final net = await Connectivity().checkConnectivity();
      if (!net.contains(ConnectivityResult.wifi) &&
          !net.contains(ConnectivityResult.ethernet)) {
        return;
      }
    }
    try {
      await backupNow(auto: true);
    } catch (e) {
      onAutoBackupFailed?.call(e);
    }
  }

  /// Set by the UI layer to show the "Cadangan gagal" toast.
  void Function(Object error)? onAutoBackupFailed;

  /// Set by the UI layer to open "Cadangan ditemukan" (FR-033).
  VoidCallback? onBackupFoundOnEmptyDevice;

  static const keyRestoreOffered = 'restore_offered';

  /// A fresh install (no accounts, no transactions) that signs in and has
  /// backups on Drive is offered a restore once.
  Future<void> _offerRestoreIfEmpty() async {
    if (history.isEmpty || _s.get(keyRestoreOffered) == 'true') return;
    final db = await DatabaseHelper.instance.database;
    final tx = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM transactions')) ??
        0;
    final acc = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM accounts')) ??
        0;
    if (tx > 0 || acc > 0) return;
    await _s.set(keyRestoreOffered, 'true');
    onBackupFoundOnEmptyDevice?.call();
  }
}

class _Cancelled implements Exception {
  const _Cancelled();
}
