import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:artavia/core/services/settings_service.dart';

/// Daily "catat transaksimu" reminder (FR-031a). Local notifications only.
class NotificationService extends GetxService {
  static NotificationService get to => Get.find();

  static const _reminderId = 1001;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<NotificationService> init() async {
    try {
      tzdata.initializeTimeZones();
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
      if (SettingsService.to.dailyReminder) {
        await _schedule(SettingsService.to.reminderTime);
      }
    } catch (e) {
      Get.log('Notification init failed: $e');
    }
    return this;
  }

  /// Asks the OS for permission. Returns false when the user declined.
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  Future<void> enable(TimeOfDay time) async {
    await SettingsService.to.set(SettingsService.keyDailyReminder, 'true');
    await SettingsService.to.set(SettingsService.keyReminderTime,
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
    await _schedule(time);
  }

  Future<void> disable() async {
    await SettingsService.to.set(SettingsService.keyDailyReminder, 'false');
    await cancel();
  }

  Future<void> cancel() async {
    if (!_ready) return;
    await _plugin.cancel(id: _reminderId);
  }

  Future<void> _schedule(TimeOfDay time) async {
    if (!_ready) return;
    await cancel();
    await _plugin.zonedSchedule(
      id: _reminderId,
      title: 'Sudah catat keuangan hari ini?',
      body: 'Luangkan sebentar untuk mencatat transaksi hari ini.',
      scheduledDate: _nextInstance(time),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Pengingat Harian',
          channelDescription: 'Pengingat harian untuk mencatat transaksi',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // Inexact avoids the restricted exact-alarm permission (research R7).
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstance(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    return next;
  }
}
