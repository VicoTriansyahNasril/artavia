import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/services/backup_codec.dart';
import 'package:artavia/core/services/backup_service.dart';
import 'package:artavia/core/services/google_drive_service.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/components/app_feedback.dart';

/// "Cadangan gagal … Data tetap aman di HP ini" with Tutup / Coba lagi
/// (FR-032). Used for manual and automatic backups.
void showBackupFailed([Object? error]) {
  AppToast.toast(
    icon: LucideIcons.cloudAlert,
    tone: colorDanger,
    title: 'Cadangan gagal',
    body:
        '${error is BackupFailure ? '${error.message}. ' : 'Periksa koneksi internet. '}'
        'Data tetap aman di HP ini.',
    actions: [
      const ToastAction('Tutup', AppToast.dismiss),
      ToastAction('Coba lagi', () => runBackup(), primary: true),
    ],
  );
}

/// Manual backup with success / failure feedback.
Future<void> runBackup() async {
  try {
    final entry = await BackupService.to.backupNow();
    if (entry != null) {
      AppToast.success('Cadangan selesai',
          '${entry.txCount} transaksi tersimpan di Google Drive');
    }
  } catch (e) {
    showBackupFailed(e);
  }
}

String formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / 1024 / 1024).toStringAsFixed(1).replaceAll('.', ',')} MB';
  }
  return '${(bytes / 1024).ceil()} KB';
}

class BackupController extends GetxController {
  BackupService get service => BackupService.to;
  GoogleDriveService get drive => GoogleDriveService.to;
  SettingsService get settings => SettingsService.to;

  final restoring = false.obs;

  /// Restore screen: chosen entry, password state.
  final selected = Rxn<BackupEntry>();
  final passwordError = false.obs;
  String password = '';

  @override
  void onInit() {
    super.onInit();
    if (drive.isConnected.value) service.refreshHistory();
    final args = Get.arguments;
    if (args is Map && args['backupNow'] == true && drive.isConnected.value) {
      Future.microtask(runBackup);
    }
    selected.value = service.history.firstOrNull;
    ever(service.history, (List<BackupEntry> h) {
      if (selected.value == null || !h.any((e) => e.id == selected.value!.id)) {
        selected.value = h.firstOrNull;
      }
    });
  }

  Future<void> connect() async {
    if (!GoogleDriveService.isConfigured) {
      AppToast.error('Backup Drive belum dikonfigurasi',
          'Web client ID Google belum dipasang di aplikasi ini');
      return;
    }
    final ok = await drive.connect();
    if (ok) {
      await settings.set(SettingsService.keyBackupAuto, 'true');
      AppToast.success('Terhubung', 'Google Drive siap dipakai');
    } else {
      AppToast.error('Gagal terhubung', 'Coba lagi beberapa saat lagi');
    }
  }

  /// "Ganti": switch to another Google account.
  Future<void> switchAccount() async {
    await drive.disconnect();
    await connect();
  }

  Future<void> disconnect() async {
    final ok = await AppDialog.confirm(
      icon: LucideIcons.unlink,
      title: 'Putuskan Google Drive?',
      message: 'Cadangan otomatis berhenti. Cadangan yang sudah ada tetap '
          'tersimpan di Google Drive.',
      confirmLabel: 'Putuskan',
      destructive: true,
    );
    if (!ok) return;
    await drive.disconnect();
  }

  Future<void> setAuto(bool v) =>
      settings.set(SettingsService.keyBackupAuto, '$v');

  Future<void> setWifiOnly(bool v) =>
      settings.set(SettingsService.keyBackupWifiOnly, '$v');

  Future<void> setPassword(String password, String hint) async {
    AppDialog.showProgress();
    try {
      await service.setPassword(password, hint: hint);
    } finally {
      AppDialog.hideProgress();
    }
    AppToast.success('Kata sandi aktif',
        'Cadangan berikutnya dikunci. Simpan kata sandi baik-baik.');
  }

  Future<void> removePassword() async {
    final ok = await AppDialog.confirm(
      title: 'Matikan kata sandi?',
      message: 'Cadangan berikutnya tidak dikunci. Cadangan lama tetap '
          'memakai kata sandi lamanya.',
      confirmLabel: 'Matikan',
    );
    if (ok) await service.setPassword(null);
  }

  /// Restores [entry]; returns true on success. Wrong password sets
  /// [passwordError] so the field turns red and shows the hint.
  Future<bool> restore(BackupEntry entry, {bool confirm = true}) async {
    if (confirm) {
      final ok = await AppDialog.confirm(
        icon: LucideIcons.history,
        title: 'Pulihkan cadangan ini?',
        message: 'Data di HP ini akan diganti dengan cadangan '
            '${entry.txCount > 0 ? 'berisi ${entry.txCount} transaksi' : 'yang dipilih'}.',
        confirmLabel: 'Pulihkan',
        destructive: true,
      );
      if (!ok) return false;
    }
    restoring.value = true;
    passwordError.value = false;
    try {
      await service.restore(entry, password: password);
      AppToast.success('Data dipulihkan', 'Semua data sudah kembali');
      return true;
    } on WrongPassword {
      passwordError.value = true;
      return false;
    } catch (e) {
      AppToast.error('Gagal memulihkan', 'Periksa koneksi lalu coba lagi');
      return false;
    } finally {
      restoring.value = false;
    }
  }
}
