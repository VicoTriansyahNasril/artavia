import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:artavia/core/services/settings_service.dart';

/// Light vibration on keypad presses and saves (Pengaturan › Getaran, FR-030).
/// Replaces the old sound effect (research R13).
class HapticsService extends GetxService {
  static HapticsService get to => Get.find();

  bool get _on => SettingsService.to.haptics;

  void tap() {
    if (_on) HapticFeedback.selectionClick();
  }

  void success() {
    if (_on) HapticFeedback.lightImpact();
  }
}
