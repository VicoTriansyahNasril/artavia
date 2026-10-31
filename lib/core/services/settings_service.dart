import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/utils/currency_format.dart';

/// Single reader/writer of the `settings` table (contracts/settings-keys.md).
/// Values are cached in memory so screens can read them synchronously.
class SettingsService extends GetxService {
  static SettingsService get to => Get.find();

  static const keyDailyReminder = 'daily_reminder';
  static const keyReminderTime = 'reminder_time';
  static const keyMonthStartDay = 'month_start_day';
  static const keyAppLock = 'app_lock';
  static const keyPinSalt = 'pin_salt';
  static const keyPinHash = 'pin_hash';
  static const keyNumberFormat = 'number_format';
  static const keyHaptics = 'haptics';
  static const keyHideOnOpen = 'hide_on_open';
  static const keyLastAccountId = 'last_account_id';
  static const keyRecentSearches = 'recent_searches';
  static const keyBackupAuto = 'backup_auto';
  static const keyBackupWifiOnly = 'backup_wifi_only';
  static const keyBackupLocked = 'backup_locked';
  static const keyBackupHint = 'backup_hint';
  static const keyLastBackupAt = 'last_backup_at';
  static const keyLastBackupBytes = 'last_backup_bytes';
  static const keyLastBackupTx = 'last_backup_tx';
  static const keyBackupNudgeHidden = 'backup_nudge_hidden';
  static const keyBudgetStep = 'onboarding_budget_step';

  final _values = <String, String>{}.obs;

  Future<SettingsService> init() async {
    await reload();
    return this;
  }

  /// Re-reads every key from the DB (e.g. after reset or restore).
  Future<void> reload() async {
    _values.assignAll(await DatabaseHelper.instance.readAllSettings());
    CurrencyService.to.useCommaSeparator = numberFormat == 'comma';
  }

  String? get(String key) => _values[key];

  Future<void> set(String key, String value) async {
    _values[key] = value;
    await DatabaseHelper.instance.saveSetting(key, value);
  }

  Future<void> remove(String key) async {
    _values.remove(key);
    await DatabaseHelper.instance.deleteSetting(key);
  }

  bool _bool(String key) => _values[key] == 'true';

  bool get dailyReminder => _bool(keyDailyReminder);
  bool get appLock => _bool(keyAppLock);
  bool get hideOnOpen => _bool(keyHideOnOpen);

  /// Haptics default on (board "Getaran"); only an explicit "false" turns it off.
  bool get haptics => _values[keyHaptics] != 'false';

  int? get lastAccountId => int.tryParse(_values[keyLastAccountId] ?? '');

  bool get backupAuto => _values[keyBackupAuto] != 'false';
  bool get backupWifiOnly => _values[keyBackupWifiOnly] != 'false';
  bool get backupLocked => _bool(keyBackupLocked);
  String? get backupHint => _values[keyBackupHint];
  DateTime? get lastBackupAt =>
      DateTime.tryParse(_values[keyLastBackupAt] ?? '');
  int get lastBackupBytes =>
      int.tryParse(_values[keyLastBackupBytes] ?? '') ?? 0;
  int get lastBackupTx => int.tryParse(_values[keyLastBackupTx] ?? '') ?? 0;

  /// "Hubungkan nanti" on the Status data card.
  bool get backupNudgeHidden => _bool(keyBackupNudgeHidden);

  /// Optional budget step after the first account (onboarding).
  bool get budgetStepPending => _bool(keyBudgetStep);

  /// Most recent search queries, newest first (max 5), stored '|'-separated.
  List<String> get recentSearches {
    final raw = _values[keyRecentSearches];
    if (raw == null || raw.isEmpty) return const [];
    return raw.split('|').where((e) => e.isNotEmpty).toList();
  }

  Future<void> addRecentSearch(String query) async {
    final q = query.trim().replaceAll('|', ' ');
    if (q.isEmpty) return;
    final list = [q, ...recentSearches.where((e) => e != q)].take(5);
    await set(keyRecentSearches, list.join('|'));
  }

  Future<void> clearRecentSearches() => remove(keyRecentSearches);

  TimeOfDay get reminderTime {
    final parts = (_values[keyReminderTime] ?? '20:00').split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 20,
      minute: int.tryParse(parts.last) ?? 0,
    );
  }

  int get monthStartDay =>
      (int.tryParse(_values[keyMonthStartDay] ?? '') ?? 1).clamp(1, 28);

  String get numberFormat => _values[keyNumberFormat] ?? 'dot';

  Future<void> setNumberFormat(String format) async {
    await set(keyNumberFormat, format);
    CurrencyService.to.useCommaSeparator = format == 'comma';
  }
}
