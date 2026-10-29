import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Points sqflite at the FFI implementation so DatabaseHelper can run in
/// plain `flutter test` (no device). Each test file runs in its own isolate
/// and gets its own databases folder, so files running in parallel never
/// share `artavia.db`.
Future<void> initTestDatabaseFactory() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final dir = Directory.systemTemp.createTempSync('artavia_test_db_');
  await databaseFactory.setDatabasesPath(dir.path);
}
