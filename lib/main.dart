import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/widgets/commons/common.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: nameApp,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: colorBackground,
        colorScheme: const ColorScheme.dark(
          primary: colorAccent,
          surface: colorCard,
        ),
        useMaterial3: true,
      ),
      initialRoute: homeRoute,
      getPages: route,
    );
  }
}
