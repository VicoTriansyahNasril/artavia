import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/services/notification_service.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/services/pin_lock_service.dart';
import 'package:artavia/core/services/privacy_service.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/core/services/theme_service.dart';
import 'package:artavia/core/utils/data_refresh.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/widgets/components/app_feedback.dart';

/// Pengaturan tab (FR-027): every row performs a real action. State is read
/// straight from [SettingsService] / [ThemeService], which are reactive.
class SettingsController extends GetxController {
  SettingsService get settings => SettingsService.to;
  ThemeService get theme => ThemeService.to;

  final isWorking = false.obs;
  final accountCount = 0.obs;
  final categoryCount = 0.obs;
  final recurringCount = 0.obs;

  String get reminderLabel {
    final t = settings.reminderTime;
    return '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';
  }

  String get numberFormatLabel =>
      settings.numberFormat == 'comma' ? '1,000' : '1.000';

  @override
  void onInit() {
    super.onInit();
    loadStats();
  }

  Future<void> loadStats() async {
    final db = DatabaseHelper.instance;
    accountCount.value =
        (await db.readAllAccounts()).where((a) => a['is_archived'] != 1).length;
    categoryCount.value = (await db.readAllCategories())
        .where((c) => c['is_archived'] != 1)
        .length;
    recurringCount.value = (await db.readRecurringRules()).length;
  }

  // ─── Tampilan ────────────────────────────────────────────────────────────

  Future<void> setTheme(ThemePref p) => theme.setTheme(p);

  Future<void> setReduceTransparency(bool v) => theme.setReduceTransparency(v);

  Future<void> setMonthStartDay(int day) async {
    await settings.set(SettingsService.keyMonthStartDay, '$day');
    PeriodService.to.resetToToday();
    refreshAllGlobalData();
  }

  Future<void> setNumberFormat(String format) async {
    await settings.setNumberFormat(format);
    refreshAllGlobalData();
    Get.forceAppUpdate();
  }

  // ─── Pengingat ───────────────────────────────────────────────────────────

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

  // ─── Keamanan ────────────────────────────────────────────────────────────

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

  /// "Sembunyikan saldo saat dibuka" also hides amounts right now.
  Future<void> toggleHideOnOpen(bool on) async {
    await settings.set(SettingsService.keyHideOnOpen, '$on');
    if (on != PrivacyService.to.masked.value) PrivacyService.to.toggle();
  }

  Future<void> toggleHaptics(bool on) =>
      settings.set(SettingsService.keyHaptics, '$on');

  // ─── Data ────────────────────────────────────────────────────────────────

  Future<void> resetAllData() async {
    final ok = await AppDialog.confirm(
      title: 'Reset seluruh data?',
      message:
          'Semua transaksi, rekening, kategori, anggaran, transaksi berulang, '
          'dan pengaturan (termasuk PIN) akan dihapus permanen dari HP ini. '
          'Cadangan di Google Drive tidak ikut terhapus.',
      confirmLabel: 'Reset seluruh data',
      destructive: true,
    );
    if (!ok) return;
    isWorking.value = true;
    try {
      await NotificationService.to.cancel();
      await DatabaseHelper.instance.resetDatabase();
      await settings.reload();
      PinLockService.to.unlock();
      await PinLockService.to.syncSecureScreen();
      PeriodService.to.resetToToday();
      refreshAllGlobalData();
      AppToast.success('Reset selesai', 'Semua data berhasil dihapus');
    } finally {
      isWorking.value = false;
    }
  }
}
