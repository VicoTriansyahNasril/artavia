import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/page/pin/lock_overlay.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/core/services/backup_service.dart';
import 'package:artavia/core/services/google_drive_service.dart';
import 'package:artavia/page/backup/backup_controller.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/core/services/theme_service.dart';
import 'package:artavia/core/services/privacy_service.dart';
import 'package:artavia/core/services/haptics_service.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/services/pin_lock_service.dart';
import 'package:artavia/core/services/recurring_service.dart';
import 'package:artavia/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  Get.put(GoogleDriveService(), permanent: true);
  await Get.putAsync(() => SettingsService().init(), permanent: true);
  Get.put(ThemeService().init(), permanent: true);
  Get.put(PrivacyService().init(), permanent: true);
  Get.put(HapticsService(), permanent: true);
  Get.put(PeriodService(), permanent: true);
  Get.put(PinLockService(), permanent: true);
  Get.put(BackupService(), permanent: true)
    ..onAutoBackupFailed = showBackupFailed
    ..onBackupFoundOnEmptyDevice = () => Get.toNamed(restoreFoundRoute);
  Get.put(RecurringService(), permanent: true);
  await RecurringService.to.runDue();
  await Get.putAsync(() => NotificationService().init(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeService.to;
    return GetMaterialApp(
      title: nameApp,
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 280),
      theme: buildAppTheme(AppPalette.light),
      darkTheme: buildAppTheme(AppPalette.dark),
      themeMode: theme.themeMode,
      initialRoute: homeRoute,
      getPages: route,
      // The PIN lock sits above the navigator so it covers every route/dialog.
      builder: (context, child) {
        _syncSystemBars();
        final scaler = theme.textScaler;
        final app = LockOverlay(child: child ?? const SizedBox());
        if (scaler == null) return app;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scaler),
          child: app,
        );
      },
    );
  }

  static void _syncSystemBars() {
    final dark = AppPalette.current.isDark;
    final icons = dark ? Brightness.light : Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: icons,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: colorCard,
      systemNavigationBarIconBrightness: icons,
    ));
  }
}

/// Material theme derived from one Kobalt [AppPalette] (dark or light).
ThemeData buildAppTheme(AppPalette p) {
  final rounded12 =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  final rounded20 =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));
  final base = p.isDark ? ThemeData.dark() : ThemeData.light();
  final scheme = p.isDark
      ? ColorScheme.dark(
          primary: p.accent,
          onPrimary: p.onAccent,
          secondary: p.accent,
          onSecondary: p.onAccent,
          surface: p.card,
          onSurface: p.text,
          surfaceContainerHighest: p.surface,
          error: p.danger,
          onError: p.onAccent,
          outline: p.divider,
        )
      : ColorScheme.light(
          primary: p.accent,
          onPrimary: p.onAccent,
          secondary: p.accent,
          onSecondary: p.onAccent,
          surface: p.card,
          onSurface: p.text,
          surfaceContainerHighest: p.surface,
          error: p.danger,
          onError: p.onAccent,
          outline: p.divider,
        );
  return ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    scaffoldBackgroundColor: p.background,
    canvasColor: p.background,
    fontFamily: AppText.family,
    colorScheme: scheme,
    textTheme: base.textTheme
        .apply(
          fontFamily: AppText.family,
          bodyColor: p.text,
          displayColor: p.text,
        )
        .copyWith(
          bodyMedium: AppText.bodySmall.copyWith(color: p.text),
          bodyLarge: AppText.body.copyWith(color: p.text),
        ),
    iconTheme: IconThemeData(color: p.text),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: p.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppText.title2.copyWith(color: p.text),
      iconTheme: IconThemeData(color: p.text),
    ),
    dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: p.glassThick,
      surfaceTintColor: Colors.transparent,
      shape: rounded20,
      titleTextStyle: AppText.title3.copyWith(fontSize: 18, color: p.text),
      contentTextStyle: AppText.bodySmall.copyWith(color: p.textOnGlass),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: p.divider,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: p.surface,
      headerForegroundColor: p.text,
      shape: rounded20,
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: p.card,
      dialBackgroundColor: p.surface,
      hourMinuteColor: p.surface,
      shape: rounded20,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      labelStyle: TextStyle(color: p.textMuted),
      hintStyle: TextStyle(color: p.textMuted),
      prefixStyle: TextStyle(color: p.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.danger, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        minimumSize: const Size(44, 48),
        textStyle: AppText.body.w600,
        shape: rounded12,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        elevation: 0,
        minimumSize: const Size(44, 48),
        textStyle: AppText.body.w600,
        shape: rounded12,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.text,
        side: BorderSide(color: p.divider),
        minimumSize: const Size(44, 48),
        shape: rounded12,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.accent,
        minimumSize: const Size(44, 44),
        textStyle: AppText.bodySmall.w600,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.accent,
      foregroundColor: p.onAccent,
      elevation: 0,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surface,
      selectedColor: p.accentSoft,
      labelStyle: AppText.label.copyWith(color: p.text),
      side: BorderSide.none,
      shape: const StadiumBorder(),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
    listTileTheme: ListTileThemeData(iconColor: p.textMuted, textColor: p.text),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.onAccent : p.switchThumbOff,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.accent : p.switchOff,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : null),
      checkColor: WidgetStateProperty.all(p.onAccent),
      side: BorderSide(color: p.switchOff, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.glassThick,
      contentTextStyle: AppText.bodySmall.copyWith(color: p.text),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
