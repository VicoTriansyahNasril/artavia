import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/widgets/commons/common.dart';

import 'db_test_helper.dart';

/// Builds a database exactly as v11 left it (legacy icons, no v12 columns).
Future<void> _writeV11Fixture(String path) async {
  final db = await databaseFactory.openDatabase(path);
  await db
      .execute('''CREATE TABLE accounts (id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL, type TEXT NOT NULL, balance INTEGER NOT NULL,
    currency_code TEXT NOT NULL DEFAULT "IDR", icon_code INTEGER, icon_path TEXT,
    color_val INTEGER, is_excluded INTEGER NOT NULL DEFAULT 0)''');
  await db
      .execute('''CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL, type TEXT NOT NULL, icon_code INTEGER, icon_path TEXT,
    color_val INTEGER)''');
  await db.execute(
      '''CREATE TABLE transactions (id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL, amount INTEGER NOT NULL, category_id INTEGER,
    note TEXT NOT NULL, account_id INTEGER, destination_account_id INTEGER,
    date TEXT NOT NULL, admin_fee INTEGER NOT NULL DEFAULT 0, admin_fee_type TEXT)''');
  await db
      .execute('''CREATE TABLE budgets (id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_id INTEGER, budget_amount INTEGER NOT NULL, month INTEGER NOT NULL,
    year INTEGER NOT NULL)''');
  await db.execute(
      'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
  await db.execute(
      '''CREATE TABLE recurring_rules (id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL, amount INTEGER NOT NULL, category_id INTEGER NOT NULL,
    account_id INTEGER NOT NULL, note TEXT NOT NULL DEFAULT '', frequency TEXT NOT NULL,
    start_date TEXT NOT NULL, last_run_date TEXT, is_active INTEGER NOT NULL DEFAULT 1)''');

  await db.insert('accounts', {
    'name': 'BCA',
    'type': 'Bank',
    'balance': 1250000,
    'icon_path': 'assets/keuangan/bank.png',
    'color_val': 0xFF7AA2F7,
  });
  await db.insert(
      'accounts', {'name': 'Dompet', 'type': 'Kas Tunai', 'balance': 50000});
  await db.insert('categories', {
    'name': 'Makanan',
    'type': 'pengeluaran',
    'icon_path': 'assets/makanan/bowl.png',
    'color_val': 0xFF7AA2F7,
  });
  await db.insert('transactions', {
    'type': 'pengeluaran',
    'amount': 45000,
    'category_id': 1,
    'note': 'Makan siang',
    'account_id': 1,
    'date': '2026-10-01T12:00:00.000',
  });
  await db.insert('budgets',
      {'category_id': 1, 'budget_amount': 500000, 'month': 10, 'year': 2026});
  // Category gone: dropped by v13.
  await db.insert('budgets',
      {'category_id': 99, 'budget_amount': 1, 'month': 10, 'year': 2026});
  await db.setVersion(11);
  await db.close();
}

void main() {
  late Directory tmp;

  setUpAll(initTestDatabaseFactory);
  setUp(() => tmp = Directory.systemTemp.createTempSync('artavia_v12_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('v11 → v12 adds columns, fills icon keys, keeps balances', () async {
    final path = p.join(tmp.path, 'artavia.db');
    await _writeV11Fixture(path);

    final db = await DatabaseHelper.instance.openAt(path);
    expect(await db.getVersion(), DatabaseHelper.dbVersion);

    Future<Set<String>> cols(String table) async =>
        (await db.rawQuery('PRAGMA table_info($table)'))
            .map((r) => r['name'] as String)
            .toSet();
    expect(await cols('transactions'),
        containsAll(['import_batch_id', 'updated_at']));
    expect(await cols('categories'),
        containsAll(['icon_key', 'sort_order', 'is_archived']));
    expect(
        await cols('accounts'),
        containsAll([
          'icon_key',
          'sort_order',
          'is_archived',
          'credit_limit',
          'due_day'
        ]));
    expect(
        await cols('import_batches'),
        containsAll(
            ['file_name', 'created_at', 'transaction_count', 'status']));

    final accounts = await db.query('accounts', orderBy: 'id');
    expect(accounts.map((a) => a['balance']), [1250000, 50000]);
    for (final a in accounts) {
      expect(IconRegistry.contains(a['icon_key'] as String?), isTrue);
    }
    // No legacy icon → falls back to the account-type icon.
    expect(accounts[1]['icon_key'], IconRegistry.accountTypeKey('Kas Tunai'));

    final cat = (await db.query('categories')).single;
    expect(cat['icon_key'], isNot(IconRegistry.fallbackKey));
    expect(cat['color_val'], 0xFF5B8CFF,
        reason: 'old blue snaps to the new accent');

    final tx = (await db.query('transactions')).single;
    expect(tx['updated_at'], tx['date']);
    expect(tx['import_batch_id'], isNull);

    final joined = await db.rawQuery(DatabaseHelper.transactionSelect);
    expect(joined.single['categoryIconKey'], cat['icon_key']);

    // v13: the budget is named after its category and linked to it.
    final budget = (await db.query('budgets')).single;
    expect(budget['name'], 'Makanan');
    expect(budget['category_id'], isNull);
    // v14: own icon/color columns, empty = follow the categories.
    expect(budget['icon_key'], isNull);
    expect(budget['color_val'], isNull);
    expect(await db.query('budget_categories'), [
      {'budget_id': budget['id'], 'category_id': 1},
    ]);
    await db.close();
  });

  test('fresh v12 database seeds categories with real icon keys', () async {
    final db =
        await DatabaseHelper.instance.openAt(p.join(tmp.path, 'fresh.db'));
    final cats = await db.query('categories');
    expect(cats, isNotEmpty);
    for (final c in cats) {
      expect(c['icon_key'], isNot(IconRegistry.fallbackKey),
          reason: '${c['name']} (${c['icon_path']})');
      expect(categoryPaletteValues, contains(c['color_val']));
    }
    await db.close();
  });
}
