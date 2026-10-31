import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:artavia/core/models/budget_import_row.dart';
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

  static const dbVersion = 14;

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
  name TEXT,
  icon_key TEXT,
  color_val INTEGER,
  budget_amount $intType,
  month $intType,
  year $intType,
  FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
)
''');
    await db.execute(_budgetCategoriesSql);

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
    if (oldVersion < 13) {
      await _migrateBudgetsV13(db);
    }
    if (oldVersion < 14) {
      // Own icon/color per budget; NULL = follow its categories.
      for (final col in ['icon_key TEXT', 'color_val INTEGER']) {
        try {
          await db.execute('ALTER TABLE budgets ADD COLUMN $col');
        } catch (_) {}
      }
    }
  }

  /// Budget ↔ category links (v13): one named budget covers 1..n expense
  /// categories; a category belongs to at most one budget per period.
  static const _budgetCategoriesSql = '''
CREATE TABLE IF NOT EXISTS budget_categories (
  budget_id INTEGER NOT NULL REFERENCES budgets (id) ON DELETE CASCADE,
  category_id INTEGER NOT NULL REFERENCES categories (id) ON DELETE CASCADE,
  PRIMARY KEY (budget_id, category_id)
)
''';

  /// v13: budgets get a free `name` and move their single `category_id`
  /// into `budget_categories`. Old rows are named after their category;
  /// rows whose category is gone are dropped. `budgets.category_id` stays
  /// (NULL) so a category delete never cascades a multi-category budget.
  Future<void> _migrateBudgetsV13(Database db) async {
    final cols = (await db.rawQuery('PRAGMA table_info(budgets)'))
        .map((r) => r['name'] as String)
        .toSet();
    // Budgets created by the v4 upgrade lack these columns.
    if (!cols.contains('category_id')) {
      await db.execute('ALTER TABLE budgets ADD COLUMN category_id INTEGER');
    }
    if (!cols.contains('name')) {
      await db.execute('ALTER TABLE budgets ADD COLUMN name TEXT');
    }
    await db.execute(_budgetCategoriesSql);
    await db.execute('''
INSERT OR IGNORE INTO budget_categories (budget_id, category_id)
SELECT b.id, b.category_id FROM budgets b
INNER JOIN categories c ON c.id = b.category_id''');
    await db.execute('''
UPDATE budgets SET name =
  (SELECT c.name FROM categories c WHERE c.id = budgets.category_id)
WHERE IFNULL(LENGTH(TRIM(name)), 0) = 0''');
    await db.execute('UPDATE budgets SET category_id = NULL');
    await pruneEmptyBudgets(db);
  }

  /// Drops budgets left without any category (after a category delete).
  static Future<void> pruneEmptyBudgets(DatabaseExecutor db) =>
      db.execute('DELETE FROM budgets WHERE id NOT IN '
          '(SELECT budget_id FROM budget_categories)');

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
    final n = await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    await pruneEmptyBudgets(db);
    return n;
  }

  // ─── Budgets CRUD ────────────────────────────────────────────────────────

  /// Budgets of one period, oldest first. Each row has `id`, `name`,
  /// `budget_amount`, `month`, `year`, `category_ids` (List<int>) and
  /// `categories` (category rows in manual order). Budgets without any
  /// category are left out.
  Future<List<Map<String, dynamic>>> readBudgetsByMonth(int year, int month) =>
      _readBudgets('WHERE b.year = ? AND b.month = ?', [year, month]);

  /// Every budget (export), by period.
  Future<List<Map<String, dynamic>>> readAllBudgets() => _readBudgets('', []);

  Future<List<Map<String, dynamic>>> _readBudgets(
      String where, List<Object?> args) async {
    final db = await instance.database;
    final budgets = await db.rawQuery(
        'SELECT b.id, b.name, b.icon_key, b.color_val, b.budget_amount, '
        'b.month, b.year FROM budgets b '
        '$where ORDER BY b.year, b.month, b.id',
        args);
    if (budgets.isEmpty) return [];
    final links = await db.rawQuery(
        'SELECT bc.budget_id, c.* FROM budget_categories bc '
        'INNER JOIN budgets b ON b.id = bc.budget_id '
        'INNER JOIN categories c ON c.id = bc.category_id '
        '$where ORDER BY c.sort_order, c.id',
        args);
    final byBudget = <int, List<Map<String, dynamic>>>{};
    for (final l in links) {
      final cat = Map<String, dynamic>.of(l)..remove('budget_id');
      byBudget.putIfAbsent(l['budget_id'] as int, () => []).add(cat);
    }
    return [
      for (final b in budgets)
        if (byBudget[b['id']] case final cats?)
          {
            ...b,
            'name': (b['name'] as String?)?.trim().isNotEmpty == true
                ? b['name']
                : cats.map((c) => c['name']).join(', '),
            'category_ids': [for (final c in cats) c['id'] as int],
            'categories': cats,
          },
    ];
  }

  /// Creates ([id] null) or updates a named budget covering [categoryIds]
  /// for one period. Those categories leave any other budget of the same
  /// period (a category counts toward one budget only); budgets emptied by
  /// that are removed. [iconKey]/[colorVal] null = follow the categories.
  /// Returns the budget id.
  Future<int> saveBudget({
    int? id,
    required String name,
    required int amount,
    required Set<int> categoryIds,
    required int month,
    required int year,
    String? iconKey,
    int? colorVal,
  }) async {
    final db = await instance.database;
    return db.transaction((txn) => _saveBudget(txn,
        id: id,
        name: name,
        amount: amount,
        categoryIds: categoryIds,
        month: month,
        year: year,
        iconKey: iconKey,
        colorVal: colorVal));
  }

  static Future<int> _saveBudget(
    Transaction txn, {
    int? id,
    required String name,
    required int amount,
    required Set<int> categoryIds,
    required int month,
    required int year,
    String? iconKey,
    int? colorVal,
  }) async {
    assert(categoryIds.isNotEmpty);
    final row = {
      'name': name.trim(),
      'budget_amount': amount,
      'month': month,
      'year': year,
      'icon_key': iconKey,
      'color_val': colorVal,
    };
    final budgetId = id ?? await txn.insert('budgets', row);
    if (id != null) {
      await txn.update('budgets', row, where: 'id = ?', whereArgs: [id]);
    }
    final marks = List.filled(categoryIds.length, '?').join(', ');
    await txn.rawDelete(
        'DELETE FROM budget_categories WHERE budget_id = ? OR '
        '(category_id IN ($marks) AND budget_id IN '
        '(SELECT id FROM budgets WHERE month = ? AND year = ?))',
        [budgetId, ...categoryIds, month, year]);
    for (final c in categoryIds) {
      await txn.insert(
          'budget_categories', {'budget_id': budgetId, 'category_id': c});
    }
    await pruneEmptyBudgets(txn);
    return budgetId;
  }

  /// Copies the budgets of one period into another. A budget is skipped
  /// when the target already has its name; categories already budgeted in
  /// the target are left out (and a budget with none left is skipped).
  /// Returns how many budgets were created.
  Future<int> copyBudgets({
    required int fromYear,
    required int fromMonth,
    required int toYear,
    required int toMonth,
  }) async {
    final source = await readBudgetsByMonth(fromYear, fromMonth);
    final target = await readBudgetsByMonth(toYear, toMonth);
    final names = {
      for (final b in target) (b['name'] as String).toLowerCase(),
    };
    final taken = {
      for (final b in target) ...(b['category_ids'] as List<int>),
    };
    final db = await instance.database;
    return db.transaction((txn) async {
      var copied = 0;
      for (final b in source) {
        final ids = {
          for (final id in b['category_ids'] as List<int>)
            if (!taken.contains(id)) id,
        };
        if (ids.isEmpty || names.contains((b['name'] as String).toLowerCase())) {
          continue;
        }
        await _saveBudget(txn,
            name: b['name'] as String,
            amount: b['budget_amount'] as int,
            categoryIds: ids,
            month: toMonth,
            year: toYear,
            iconKey: b['icon_key'] as String?,
            colorVal: b['color_val'] as int?);
        taken.addAll(ids);
        copied++;
      }
      return copied;
    });
  }

  /// Writes imported budgets in one DB transaction. Categories are matched
  /// by name (expense, any case, archived too); missing ones are created.
  /// A budget with the same name in its period is updated, else created.
  Future<BudgetImportResult> importBudgets(
      List<BudgetImportRow> rows) async {
    final db = await instance.database;
    return db.transaction((txn) async {
      final cats = await txn.query('categories',
          where: 'type = ?', whereArgs: ['pengeluaran']);
      final byName = {
        for (final c in cats)
          (c['name'] as String).toLowerCase(): c['id'] as int,
      };
      var sortOrder = cats.length;
      var created = 0, updated = 0, newCategories = 0;
      for (final r in rows) {
        final ids = <int>{};
        for (final name in r.categories) {
          final key = name.toLowerCase();
          var id = byName[key];
          if (id == null) {
            id = await txn.insert('categories', {
              'name': name,
              'type': 'pengeluaran',
              'icon_key': IconRegistry.fallbackKey,
              'color_val': categoryPaletteValues[
                  sortOrder % categoryPaletteValues.length],
              'sort_order': sortOrder++,
            });
            byName[key] = id;
            newCategories++;
          }
          ids.add(id);
        }
        final existing = await txn.query('budgets',
            columns: ['id'],
            where: 'year = ? AND month = ? AND LOWER(name) = ?',
            whereArgs: [r.year, r.month, r.name.toLowerCase()]);
        final id = existing.isEmpty ? null : existing.first['id'] as int;
        await _saveBudget(txn,
            id: id,
            name: r.name,
            amount: r.amount,
            categoryIds: ids,
            month: r.month,
            year: r.year,
            iconKey: r.iconKey,
            colorVal: r.colorVal);
        id == null ? created++ : updated++;
      }
      return BudgetImportResult(created, updated, newCategories);
    });
  }

  /// Sets the limit of the budget holding [categoryId] in that period, or
  /// creates a one-category budget named after it (suggestions, onboarding).
  Future<int> upsertBudget(
      {required int categoryId,
      required int amount,
      required int month,
      required int year}) async {
    final existing = (await readBudgetsByMonth(year, month)).firstWhere(
        (b) => (b['category_ids'] as List).contains(categoryId),
        orElse: () => const {});
    if (existing.isNotEmpty) {
      return saveBudget(
          id: existing['id'] as int,
          name: existing['name'] as String,
          amount: amount,
          categoryIds: {...(existing['category_ids'] as List).cast<int>()},
          month: month,
          year: year,
          iconKey: existing['icon_key'] as String?,
          colorVal: existing['color_val'] as int?);
    }
    final db = await instance.database;
    final cat = await db.query('categories',
        columns: ['name'], where: 'id = ?', whereArgs: [categoryId]);
    return saveBudget(
        name: cat.isEmpty ? '' : cat.first['name'] as String,
        amount: amount,
        categoryIds: {categoryId},
        month: month,
        year: year);
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
