import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/services/csv_service.dart';
import 'package:artavia/core/services/notification_service.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/services/pin_lock_service.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/core/utils/data_refresh.dart';
import 'package:artavia/page/home/home_controller.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/widgets/components/app_feedback.dart';

/// Every item on the Pengaturan screen performs a real action (FR-031).
/// State is read straight from [SettingsService], whose map is reactive.
class SettingsController extends GetxController {
  SettingsService get settings => SettingsService.to;

  final isWorking = false.obs;

  String get reminderLabel {
    final t = settings.reminderTime;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String get numberFormatLabel =>
      settings.numberFormat == 'comma' ? '1,000' : '1.000';

  // ─── Pengingat Harian ────────────────────────────────────────────────────

  Future<void> toggleReminder(bool on) async {
    if (!on) {
      await NotificationService.to.disable();
      return;
    }
    final granted = await NotificationService.to.requestPermission();
    if (!granted) {
      AppToast.warning('Izin ditolak',
          'Aktifkan izin notifikasi Artavia di pengaturan perangkat.');
      return;
    }
    await NotificationService.to.enable(settings.reminderTime);
    AppToast.success(
        'Pengingat aktif', 'Kami akan mengingatkan setiap $reminderLabel');
  }

  Future<void> pickReminderTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: settings.reminderTime,
      helpText: 'Jam pengingat',
    );
    if (picked == null) return;
    await NotificationService.to.enable(picked);
  }

  // ─── Mulai Bulan Pada ────────────────────────────────────────────────────

  Future<void> setMonthStartDay(int day) async {
    await settings.set(SettingsService.keyMonthStartDay, '$day');
    PeriodService.to.resetToToday();
    refreshAllGlobalData();
  }

  // ─── Kunci PIN ───────────────────────────────────────────────────────────

  Future<void> togglePin(bool on) async {
    final done = await Get.toNamed(pinRoute,
        arguments: {'mode': on ? 'setup' : 'disable'});
    if (done != true) return;
    if (on) {
      AppToast.success('PIN aktif', 'Aplikasi akan meminta PIN saat dibuka');
    } else {
      AppToast.info('PIN nonaktif', 'Kunci aplikasi telah dimatikan');
    }
  }

  // ─── Data ────────────────────────────────────────────────────────────────

  /// "Cadangkan Data" reuses the Cloud Backup section on the Saya tab.
  void openBackup() {
    Get.until((route) => route.isFirst);
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().changePage(3);
    }
  }

  Future<void> exportCsv() async {
    if (isWorking.value) return;
    isWorking.value = true;
    try {
      final count = await CsvService.exportAndShare();
      if (count == 0) {
        AppToast.info('Ekspor CSV', 'Belum ada transaksi untuk diekspor');
      }
    } catch (e) {
      AppToast.error('Ekspor gagal', 'File CSV tidak dapat dibuat');
    } finally {
      isWorking.value = false;
    }
  }

  Future<void> importCsv() async {
    if (isWorking.value) return;
    isWorking.value = true;
    try {
      final result = await CsvService.pickAndValidate();
      if (result == null) return;
      if (result.valid.isEmpty) {
        AppToast.error('Impor gagal',
            result.errors.isEmpty ? 'File kosong' : result.errors.first);
        return;
      }
      if (!await _confirmImport(result)) return;
      final count = await CsvService.import(result.valid);
      refreshAllGlobalData();
      AppToast.success('Impor selesai', '$count transaksi berhasil diimpor');
    } catch (e) {
      AppToast.error('Impor gagal', 'File tidak dapat dibaca atau disimpan');
    } finally {
      isWorking.value = false;
    }
  }

  Future<bool> _confirmImport(CsvImportResult result) {
    final skipped = result.errors.length;
    final details = result.errors.take(3).join('\n');
    return AppDialog.confirm(
      title: 'Impor ${result.valid.length} transaksi?',
      message: [
        'Transaksi akan ditambahkan ke data yang ada dan saldo rekening disesuaikan.',
        if (skipped > 0)
          '\n$skipped baris dilewati:\n$details${skipped > 3 ? '\n…' : ''}',
      ].join('\n'),
      confirmLabel: 'Impor',
    );
  }

  Future<void> resetAllData() async {
    final ok = await AppDialog.confirm(
      title: 'Reset Seluruh Data',
      message:
          'Semua transaksi, rekening, kategori kustom, anggaran, transaksi '
          'berulang, dan pengaturan (termasuk PIN) akan dihapus permanen. '
          'Tindakan ini tidak dapat dibatalkan.',
      confirmLabel: 'Reset',
      destructive: true,
    );
    if (!ok) return;
    isWorking.value = true;
    try {
      await NotificationService.to.cancel();
      await DatabaseHelper.instance.resetDatabase();
      await settings.reload();
      PinLockService.to.unlock();
      PeriodService.to.resetToToday();
      refreshAllGlobalData();
      AppToast.success('Reset selesai', 'Semua data berhasil dihapus');
    } finally {
      isWorking.value = false;
    }
  }

  // ─── Tampilan & Suara ────────────────────────────────────────────────────

  Future<void> setNumberFormat(String format) async {
    await settings.setNumberFormat(format);
    refreshAllGlobalData();
    Get.forceAppUpdate();
  }

  Future<void> toggleSound(bool on) =>
      settings.set(SettingsService.keySoundEffect, '$on');
}
