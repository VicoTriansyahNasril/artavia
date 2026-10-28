import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/widgets/commons/common.dart';

/// One look for every toast in the app: calm surface, colored icon, bottom.
class AppToast {
  AppToast._();

  static void success(String title, String message) =>
      _show(title, message, Icons.check_circle_rounded, colorIncome);

  static void info(String title, String message) =>
      _show(title, message, Icons.info_rounded, colorAccent);

  /// Validation-style warnings are de-duplicated so repeated taps don't stack.
  static void warning(String title, String message) {
    if (Get.isSnackbarOpen) return;
    _show(title, message, Icons.warning_amber_rounded, colorWarning);
  }

  static void error(String title, String message) =>
      _show(title, message, Icons.error_rounded, colorExpense);

  static void _show(String title, String message, IconData icon, Color tone) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: colorSurface,
      colorText: colorText,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
      icon: Icon(icon, color: tone),
      leftBarIndicatorColor: tone,
      shouldIconPulse: false,
    );
  }
}

/// One look for every confirmation dialog.
class AppDialog {
  AppDialog._();

  /// Returns `true` when the user confirmed.
  static Future<bool> confirm({
    required String title,
    required String message,
    String confirmLabel = 'Ya',
    String cancelLabel = 'Batal',
    bool destructive = false,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelLabel, style: const TextStyle(color: colorGrey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: destructive ? colorExpense : colorAccent,
              foregroundColor: colorOnAccent,
            ),
            onPressed: () => Get.back(result: true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Blocking spinner for long operations; close with [hideProgress].
  static void showProgress() {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
  }

  static void hideProgress() {
    if (Get.isDialogOpen ?? false) Get.back();
  }
}
