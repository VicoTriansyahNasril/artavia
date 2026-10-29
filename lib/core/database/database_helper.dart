import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:artavia/core/database/dummy_data.dart';
import 'package:artavia/widgets/commons/common.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('artavia.db');
    return _database!;
  }

  static const dbVersion = 12;

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    return openAt(join(dbPath, filePath));
  }

  /// Opens (creating/upgrading) a database file at [path]. Tests use this with
  /// an ffi factory and an explicit [version] to build older fixtures.
  @visibleForTesting
  Future<Database> openAt(String path, {int version = dbVersion}) {
    return openDatabase(
      path,
      version: version,
      onConfigure: _onConfigure,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: _onOpen,
    );
  }

  /// Indexes for the hot queries (period ranges, per-account and per-import
  /// lookups). Idempotent, so databases already on v12 get them too.
  Future _onOpen(Database db) async {
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_account '
        'ON transactions(account_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_batch '
        'ON transactions(import_batch_id)');
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static const _recurringRulesSql = '''
CREATE TABLE IF NOT EXISTS recurring_rules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  amount INTEGER NOT NULL,
  category_id INTEGER NOT NULL,
  account_id INTEGER NOT NULL,
  note TEXT NOT NULL DEFAULT '',
  frequency TEXT NOT NULL,
  start_date TEXT NOT NULL,
  last_run_date TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE,
  FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
)
''';

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE transactions (
  id $idType,
  type $textType,
  amount $intType,
  category_id INTEGER,
  note $textType,
  account_id INTEGER,
  destination_account_id INTEGER,
  date $textType,
  admin_fee INTEGER NOT NULL DEFAULT 0,
  admin_fee_type TEXT,
  import_batch_id INTEGER,
  updated_at TEXT,
  FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT,
  FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE RESTRICT,
  FOREIGN KEY (destination_account_id) REFERENCES accounts (id) ON DELETE RESTRICT,
  FOREIGN KEY (import_batch_id) REFERENCES import_batches (id) ON DELETE SET NULL
)
''');

    await db.execute(_importBatchesSql);

    await db.execute('''
CREATE TABLE accounts (
  id $idType,
  name $textType,
  type $textType,
  balance $intType,
  currency_code TEXT NOT NULL DEFAULT "IDR",
  icon_code INTEGER,
  icon_path TEXT,
  color_val INTEGER,
  is_excluded INTEGER NOT NULL DEFAULT 0,
  icon_key TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_archived INTEGER NOT NULL DEFAULT 0,
  credit_limit INTEGER,
  due_day INTEGER
)
''');

    await db.execute('''
CREATE TABLE categories (
  id $idType,
  name $textType,
  type $textType,
  icon_code INTEGER,
  icon_path TEXT,
  color_val INTEGER,
  icon_key TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_archived INTEGER NOT NULL DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE budgets (
  id $idType,
  category_id INTEGER,
  budget_amount $intType,
  month $intType,
  year $intType,
  FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
''');

    await db.execute(_recurringRulesSql);

    // Seed Categories
    final initialCategories = [
      // Pengeluaran
      {
        'name': 'Makanan',
        'type': 'pengeluaran',
        'icon_code': null,
        'icon_path': 'assets/makanan/bowl.png',
        'color_val': 0xFFE59A6B
      },
      {
        'name': 'Minuman',
        'type': 'pengeluaran',
        'icon_code': null,
        'icon_path': 'assets/makanan/soft-drink.png',
        'color_val': 0xFF4FB6B0
      },
      {
        'name': 'Belanja',
        'type': 'pengeluaran',
        'icon_code': null,
        'icon_path': 'assets/belanja/shopping-bag.png',
        'color_val': 0xFFD98AA8
      },
      {
        'name': 'Transportasi',
        'type': 'pengeluaran',
        'icon_code': null,
        'icon_path': 'assets/transportasi/car.png',
        'color_val': 0xFF5FA8D3
      },
      {
        'name': 'Kesehatan',
        'type': 'pengeluaran',
        'icon_code': null,
        'icon_path': 'assets/kesehatan/health-care.png',
        'color_val': 0xFFE07A7A
      },
      {
        'name': 'Hiburan',
        'type': 'pengeluaran',
        'icon_code': null,
        'icon_path': 'assets/hiburan/cinema.png',
        'color_val': 0xFFC987C9
      },
      {
        'name': 'Pendidikan',
        'type': 'pengeluaran',
        'icon_code': null,
        'icon_path': 'assets/pendidikan/education.png',
        'color_val': 0xFF7AA2F7
      },
      {
        'name': 'Olahraga',
        'type': 'pengeluaran',
        'icon_code': null,
        'icon_path': 'assets/olahraga/sport.png',
        'color_val': 0xFFA3BE6C
      },
      {
        'name': 'Liburan',
        'type': 'pengeluaran',
        'icon_code': null,
        'icon_path': 'assets/berpergian/travel.png',
        'color_val': 0xFFE0B25C
      },
      {
        'name': 'Pribadi',
        'type': 'pengeluaran',
        'icon_code': null,
        'icon_path': 'assets/pribadi/briefcase.png',
        'color_val': 0xFF8D94A3
      },
      {
        'name': 'Tagihan',
        'type': 'pengeluaran',
        'icon_code': null,
        'icon_path': 'assets/pribadi/wifi.png',
        'color_val': 0xFF9D8CE6
      },

      // Pemasukan
      {
        'name': 'Gaji',
        'type': 'pemasukan',
        'icon_code': null,
        'icon_path': 'assets/keuangan/uang.png',
        'color_val': 0xFF5FBF8F
      },
      {
        'name': 'Bonus',
        'type': 'pemasukan',
        'icon_code': null,
        'icon_path': 'assets/keuangan/coin.png',
        'color_val': 0xFFA3BE6C
      },
      {
        'name': 'Investasi',
        'type': 'pemasukan',
        'icon_code': null,
        'icon_path': 'assets/keuangan/stock.png',
        'color_val': 0xFF4FB6B0
      },
      {
        'name': 'Bisnis',
        'type': 'pemasukan',
        'icon_code': null,
        'icon_path': 'assets/pribadi/meeting.png',
        'color_val': 0xFF7AA2F7
      },
      {
        'name': 'Tabungan',
        'type': 'pemasukan',
        'icon_code': null,
        'icon_path': 'assets/keuangan/nabung.png',
        'color_val': 0xFFE0B25C
      },
    ];
    final batch = db.batch();
    for (var cat in initialCategories) {
      batch.insert('categories', cat);
    }
    await batch.commit(noResult: true);

    if (useDummyData) {
      await DummyDataGenerator.generate(db);
    }
    await _backfillV12(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  icon_code INTEGER,
  color_val INTEGER
)
''');
      final initialCategories = [
        {'name': 'Makanan', 'type': 'pengeluaran'},
        {'name': 'Minuman', 'type': 'pengeluaran'},
        {'name': 'Belanja', 'type': 'pengeluaran'},
        {'name': 'Transportasi', 'type': 'pengeluaran'},
        {'name': 'Gaji', 'type': 'pemasukan'},
        {'name': 'Bonus', 'type': 'pemasukan'},
      ];
      for (var cat in initialCategories) {
        await db.insert('categories', cat);
      }
    }
    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE accounts ADD COLUMN type TEXT NOT NULL DEFAULT "Kas Pribadi"');
    }
    if (oldVersion < 4) {
      // Add budgets table
      await db.execute('''
CREATE TABLE IF NOT EXISTS budgets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT,
  budget_amount INTEGER NOT NULL,
  month INTEGER NOT NULL,
  year INTEGER NOT NULL
)
''');
      // Add settings table
      await db.execute('''
CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
''');
    }
    if (oldVersion < 5) {
      // Add icon_code, color_val, is_excluded to accounts if not exist
      try {
        await db.execute('ALTER TABLE accounts ADD COLUMN icon_code INTEGER');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE accounts ADD COLUMN color_val INTEGER');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE accounts ADD COLUMN is_excluded INTEGER NOT NULL DEFAULT 0');
      } catch (_) {}
    }
    if (oldVersion < 7) {
      try {
        await db
            .execute('ALTER TABLE transactions ADD COLUMN category_id INTEGER');
      } catch (_) {}
      try {
        await db
            .execute('ALTER TABLE transactions ADD COLUMN account_id INTEGER');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN destination_account_id INTEGER');
      } catch (_) {}
    }
    if (oldVersion < 8) {
      // Add currency support to accounts
      try {
        await db.execute(
            'ALTER TABLE accounts ADD COLUMN currency_code TEXT NOT NULL DEFAULT "IDR"');
      } catch (_) {}
    }
    if (oldVersion < 9) {
      try {
        await db.execute('ALTER TABLE categories ADD COLUMN icon_path TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE accounts ADD COLUMN icon_path TEXT');
      } catch (_) {}
    }
    if (oldVersion < 10) {
      try {
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN admin_fee INTEGER NOT NULL DEFAULT 0');
      } catch (_) {}
      try {
        await db
            .execute('ALTER TABLE transactions ADD COLUMN admin_fee_type TEXT');
      } catch (_) {}
    }
    if (oldVersion < 11) {
      await db.execute(_recurringRulesSql);
    }
    if (oldVersion < 12) {
      await db.execute(_importBatchesSql);
      const columns = {
        'transactions': [
          'import_batch_id INTEGER REFERENCES import_batches (id) ON DELETE SET NULL',
          'updated_at TEXT',
        ],
        'categories': [
          'icon_key TEXT',
          'sort_order INTEGER NOT NULL DEFAULT 0',
          'is_archived INTEGER NOT NULL DEFAULT 0',
        ],
        'accounts': [
          'icon_key TEXT',
          'sort_order INTEGER NOT NULL DEFAULT 0',
          'is_archived INTEGER NOT NULL DEFAULT 0',
          'credit_limit INTEGER',
          'due_day INTEGER',
        ],
      };
      for (final entry in columns.entries) {
        for (final col in entry.value) {
          try {
            await db.execute('ALTER TABLE ${entry.key} ADD COLUMN $col');
          } catch (_) {}
        }
      }
      await _backfillV12(db);
    }
  }

  static const _importBatchesSql = '''
CREATE TABLE IF NOT EXISTS import_batches (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  file_name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  transaction_count INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  cancelled_at TEXT
)
''';

  /// v12 data fill: Lucide `icon_key` from legacy icons, `sort_order` from id
  /// order, legacy colors snapped to the Kobalt palette, `updated_at` = date.
  /// Idempotent — only touches rows that still lack the new values.
  Future<void> _backfillV12(Database db) async {
    final batch = db.batch();
    for (final table in ['categories', 'accounts']) {
      final rows = await db.query(table, orderBy: 'id ASC');
      for (var i = 0; i < rows.length; i++) {
        final r = rows[i];
        final hasKey = IconRegistry.contains(r['icon_key'] as String?);
        final legacy = IconRegistry.legacyToKey(
            iconPath: r['icon_path'] as String?,
            iconCode: r['icon_code'] as int?);
        final key = hasKey
            ? r['icon_key']
            : table == 'accounts' && legacy == IconRegistry.fallbackKey
                ? IconRegistry.accountTypeKey(r['type'] as String? ?? '')
                : legacy;
        final color = r['color_val'] as int?;
        batch.update(
          table,
          {
            'icon_key': key,
            if (!hasKey) 'sort_order': i,
            if (color != null) 'color_val': nearestPaletteValue(color),
          },
          where: 'id = ?',
          whereArgs: [r['id']],
        );
      }
    }
    batch.rawUpdate(
        'UPDATE transactions SET updated_at = date WHERE updated_at IS NULL');
    await batch.commit(noResult: true);
  }

  // ─── Transactions (read) ─────────────────────────────────────────────────
  // Mutations live in transaction_store.dart so balances are always updated
  // in the same DB transaction as the row change.

  static const transactionSelect = '''
      SELECT t.*, c.name as categoryName, c.icon_code as categoryIconCode, c.icon_path as categoryIconPath, c.color_val as categoryColorVal,
             c.icon_key as categoryIconKey, c.is_archived as categoryIsArchived,
             a.name as accountName, da.name as destinationAccountName
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      LEFT JOIN accounts a ON t.account_id = a.id
      LEFT JOIN accounts da ON t.destination_account_id = da.id
  ''';

  Future<List<Map<String, dynamic>>> readAllTransactions() async {
    final db = await instance.database;
    return db.rawQuery('$transactionSelect ORDER BY t.date DESC');
  }

  /// Transactions with `start <= date < end`, newest first.
  Future<List<Map<String, dynamic>>> readTransactionsByRange(
      DateTime start, DateTime end) async {
    final db = await instance.database;
    return db.rawQuery(
      '$transactionSelect WHERE t.date >= ? AND t.date < ? ORDER BY t.date DESC',
      [start.toIso8601String(), end.toIso8601String()],
    );
  }

  /// Calendar-month helper (Kalender always uses calendar months).
  Future<List<Map<String, dynamic>>> readTransactionsByMonth(
      int year, int month) {
    return readTransactionsByRange(
        DateTime(year, month, 1), DateTime(year, month + 1, 1));
  }

  Future<List<Map<String, dynamic>>> searchTransactions(String query) async {
    final db = await instance.database;
    return db.rawQuery(
      '$transactionSelect WHERE t.note LIKE ? OR c.name LIKE ? '
      'OR a.name LIKE ? OR da.name LIKE ? ORDER BY t.date DESC',
      List.filled(4, '%$query%'),
    );
  }

  /// How often each category was used for [type] (Catat grid ranking).
  Future<Map<int, int>> categoryUsage(String type) async {
    final db = await instance.database;
    final rows = await db.rawQuery(
      'SELECT category_id, COUNT(*) AS n FROM transactions '
      'WHERE type = ? AND category_id IS NOT NULL GROUP BY category_id',
      [type],
    );
    return {for (final r in rows) r['category_id'] as int: r['n'] as int};
  }

  /// Transactions that use an account (either side of a transfer).
  Future<int> countAccountTransactions(int accountId) async {
    final db = await instance.database;
    final r = await db.rawQuery(
        'SELECT COUNT(*) AS n FROM transactions '
        'WHERE account_id = ? OR destination_account_id = ?',
        [accountId, accountId]);
    return r.first['n'] as int;
  }

  /// Transactions per category id (Kategori list subtitles, delete dialog).
  Future<Map<int, int>> transactionCountByCategory() async {
    final db = await instance.database;
    final rows =
        await db.rawQuery('SELECT category_id, COUNT(*) AS n FROM transactions '
            'WHERE category_id IS NOT NULL GROUP BY category_id');
    return {for (final r in rows) r['category_id'] as int: r['n'] as int};
  }

  /// Persists a manual order: `sort_order` = position in [ids].
  Future<void> saveSortOrder(String table, List<int> ids) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var i = 0; i < ids.length; i++) {
      batch.update(table, {'sort_order': i},
          where: 'id = ?', whereArgs: [ids[i]]);
    }
    await batch.commit(noResult: true);
  }

  /// Import history, newest first, with how many of each batch's rows are
  /// still present and how many were edited after the import.
  Future<List<Map<String, dynamic>>> readImportBatches() async {
    final db = await instance.database;
    return db.rawQuery('''
      SELECT b.*,
        (SELECT COUNT(*) FROM transactions t WHERE t.import_batch_id = b.id)
          AS remaining,
        (SELECT COUNT(*) FROM transactions t WHERE t.import_batch_id = b.id
          AND t.updated_at > b.created_at) AS edited
      FROM import_batches b ORDER BY b.created_at DESC
    ''');
  }

  // ─── Accounts CRUD ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> readAllAccounts() async {
    final db = await instance.database;
    return await db.query('accounts', orderBy: 'sort_order ASC, name ASC');
  }

  Future<int> insertAccount(Map<String, dynamic> account) async {
    final db = await instance.database;
    return await db.insert('accounts', account);
  }

  Future<int> updateAccount(int id, Map<String, dynamic> account) async {
    final db = await instance.database;
    return await db
        .update('accounts', account, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAccount(int id) async {
    final db = await instance.database;
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Categories CRUD ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> readAllCategories() async {
    final db = await instance.database;
    return await db.query('categories', orderBy: 'sort_order ASC, id ASC');
  }

  Future<int> insertCategory(Map<String, dynamic> category) async {
    final db = await instance.database;
    return await db.insert('categories', category);
  }

  Future<int> updateCategory(int id, Map<String, dynamic> category) async {
    final db = await instance.database;
    return await db
        .update('categories', category, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Budgets CRUD ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> readBudgetsByMonth(
      int year, int month) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT b.*, c.name as categoryName, c.type as categoryType, c.icon_code as categoryIconCode, c.icon_path as categoryIconPath, c.color_val as categoryColorVal, c.icon_key as categoryIconKey
      FROM budgets b
      INNER JOIN categories c ON b.category_id = c.id
      WHERE b.year = ? AND b.month = ?
    ''', [year, month]);
  }

  Future<int> upsertBudget(
      {required int categoryId,
      required int amount,
      required int month,
      required int year}) async {
    final db = await instance.database;
    final existing = await db.query(
      'budgets',
      where: 'category_id = ? AND month = ? AND year = ?',
      whereArgs: [categoryId, month, year],
    );
    if (existing.isNotEmpty) {
      return await db.update(
        'budgets',
        {'budget_amount': amount},
        where: 'category_id = ? AND month = ? AND year = ?',
        whereArgs: [categoryId, month, year],
      );
    } else {
      return await db.insert('budgets', {
        'category_id': categoryId,
        'budget_amount': amount,
        'month': month,
        'year': year,
      });
    }
  }

  Future<int> deleteBudget(int id) async {
    final db = await instance.database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Settings CRUD ───────────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  Future<int> saveSetting(String key, String value) async {
    final db = await instance.database;
    return await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, String>> readAllSettings() async {
    final db = await instance.database;
    final rows = await db.query('settings');
    return {for (final r in rows) r['key'] as String: r['value'] as String};
  }

  Future<int> deleteSetting(String key) async {
    final db = await instance.database;
    return db.delete('settings', where: 'key = ?', whereArgs: [key]);
  }

  // ─── Recurring rules CRUD ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> readRecurringRules() async {
    final db = await instance.database;
    return db.rawQuery('''
      SELECT r.*, c.name as categoryName, c.icon_code as categoryIconCode, c.icon_path as categoryIconPath, c.color_val as categoryColorVal, c.icon_key as categoryIconKey,
             a.name as accountName
      FROM recurring_rules r
      LEFT JOIN categories c ON r.category_id = c.id
      LEFT JOIN accounts a ON r.account_id = a.id
      ORDER BY r.is_active DESC, r.start_date ASC
    ''');
  }

  Future<int> insertRecurringRule(Map<String, dynamic> rule) async {
    final db = await instance.database;
    return db.insert('recurring_rules', rule);
  }

  Future<int> updateRecurringRule(int id, Map<String, dynamic> rule) async {
    final db = await instance.database;
    return db.update('recurring_rules', rule, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteRecurringRule(int id) async {
    final db = await instance.database;
    return db.delete('recurring_rules', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = _database;
    _database = null;
    await db?.close();
  }

  /// Absolute path of the live database file.
  Future<String> databaseFilePath() async =>
      join(await getDatabasesPath(), 'artavia.db');

  /// Swaps the live database for [file] (already integrity-checked) and
  /// reopens it, which runs `onUpgrade` for older backups.
  Future<void> replaceDatabaseWith(File file) async {
    await close();
    await file.copy(await databaseFilePath());
    await database;
  }

  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'artavia.db');

    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    await deleteDatabase(path);
    await database; // Re-initialize
  }
}
