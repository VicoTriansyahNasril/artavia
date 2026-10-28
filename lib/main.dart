import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/page/pin/lock_overlay.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/core/services/google_drive_service.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/services/sound_service.dart';
import 'package:artavia/core/services/pin_lock_service.dart';
import 'package:artavia/core/services/recurring_service.dart';
import 'package:artavia/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  Get.put(GoogleDriveService(), permanent: true);
  await Get.putAsync(() => SettingsService().init(), permanent: true);
  Get.put(PeriodService(), permanent: true);
  Get.put(SoundService(), permanent: true);
  Get.put(PinLockService(), permanent: true);
  Get.put(RecurringService(), permanent: true);
  await RecurringService.to.runDue();
  await Get.putAsync(() => NotificationService().init(), permanent: true);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: colorCard,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: nameApp,
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 280),
      theme: buildAppTheme(),
      initialRoute: homeRoute,
      getPages: route,
      // The PIN lock sits above the navigator so it covers every route/dialog.
      builder: (context, child) =>
          LockOverlay(child: child ?? const SizedBox()),
    );
  }
}

ThemeData buildAppTheme() {
  final rounded12 =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  final rounded10 =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: colorBackground,
    canvasColor: colorBackground,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.dark(
      primary: colorAccent,
      onPrimary: colorOnAccent,
      secondary: colorAccent,
      onSecondary: colorOnAccent,
      surface: colorCard,
      onSurface: colorText,
      surfaceContainerHighest: colorSurface,
      error: colorExpense,
      onError: colorOnAccent,
      outline: colorDivider,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: colorText,
          displayColor: colorText,
        ),
    iconTheme: const IconThemeData(color: colorText),
    appBarTheme: const AppBarTheme(
      backgroundColor: colorBackground,
      foregroundColor: colorText,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: colorText,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: colorText),
    ),
    dividerTheme:
        const DividerThemeData(color: colorDivider, thickness: 1, space: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: colorCard,
      surfaceTintColor: Colors.transparent,
      shape: rounded12,
      titleTextStyle: const TextStyle(
          color: colorText, fontSize: 17, fontWeight: FontWeight.w600),
      contentTextStyle:
          const TextStyle(color: colorGrey, fontSize: 14, height: 1.4),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: colorCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: colorCard,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: colorSurface,
      headerForegroundColor: colorText,
      shape: rounded12,
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: colorCard,
      dialBackgroundColor: colorSurface,
      hourMinuteColor: colorSurface,
      shape: rounded12,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorSurface,
      labelStyle: const TextStyle(color: colorGrey),
      hintStyle: const TextStyle(color: colorGrey),
      prefixStyle: const TextStyle(color: colorGrey),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: colorAccent),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorAccent,
        foregroundColor: colorOnAccent,
        shape: rounded10,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorAccent,
        foregroundColor: colorOnAccent,
        elevation: 0,
        shape: rounded10,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorText,
        side: const BorderSide(color: colorDivider),
        shape: rounded10,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: colorAccent),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: colorAccent,
      foregroundColor: colorOnAccent,
      elevation: 0,
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: colorSurface,
      selectedColor: colorAccentDim,
      labelStyle: TextStyle(color: colorText),
      side: BorderSide.none,
      shape: StadiumBorder(),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: colorAccent),
    listTileTheme:
        const ListTileThemeData(iconColor: colorGrey, textColor: colorText),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? colorOnAccent : colorGrey,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? colorAccent : colorSurface,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: colorSurface,
      contentTextStyle: TextStyle(color: colorText),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
