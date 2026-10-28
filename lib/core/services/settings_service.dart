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
  static const keySoundEffect = 'sound_effect';

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
  bool get soundEffect => _bool(keySoundEffect);

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
