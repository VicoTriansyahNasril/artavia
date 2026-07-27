import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/widgets/commons/common.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Make status bar transparent so content bleeds through
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
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: colorBackground,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: colorAccent,
          surface: colorCard,
          onPrimary: colorBlack,
          onSurface: colorWhite,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: colorBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: colorWhite,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: colorWhite),
        ),
        dividerTheme: const DividerThemeData(
          color: colorDivider,
          thickness: 1,
          space: 1,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? colorBlack : colorGrey,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? colorAccent : colorSurface,
          ),
        ),
        useMaterial3: true,
      ),
      initialRoute: homeRoute,
      getPages: route,
    );
  }
}
