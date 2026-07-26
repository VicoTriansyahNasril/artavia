import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('artavia.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE transactions (
  id $idType,
  type $textType,
  amount $intType,
  category $textType,
  note $textType,
  account $textType,
  date $textType
)
''');

    await db.execute('''
CREATE TABLE accounts (
  id $idType,
  name $textType,
  type $textType,
  balance $intType,
  icon_code INTEGER,
  color_val INTEGER,
  is_excluded INTEGER NOT NULL DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE categories (
  id $idType,
  name $textType,
  type $textType,
  icon_code INTEGER,
  color_val INTEGER
)
''');

    await db.execute('''
CREATE TABLE budgets (
  id $idType,
  category TEXT,
  budget_amount $intType,
  month $intType,
  year $intType
)
''');

    await db.execute('''
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
''');

    // Seed Categories
    final initialCategories = [
      {'name': 'Makanan', 'type': 'pengeluaran', 'icon_code': 0xe57a, 'color_val': 0xFF4CAF50},
      {'name': 'Minuman', 'type': 'pengeluaran', 'icon_code': 0xe44f, 'color_val': 0xFF2196F3},
      {'name': 'Belanja', 'type': 'pengeluaran', 'icon_code': 0xe549, 'color_val': 0xFFFF9800},
      {'name': 'Transportasi', 'type': 'pengeluaran', 'icon_code': 0xe1d0, 'color_val': 0xFF9C27B0},
      {'name': 'Kesehatan', 'type': 'pengeluaran', 'icon_code': 0xe3f3, 'color_val': 0xFFF44336},
      {'name': 'Hiburan', 'type': 'pengeluaran', 'icon_code': 0xe40c, 'color_val': 0xFFE91E63},
      {'name': 'Gaji', 'type': 'pemasukan', 'icon_code': 0xe263, 'color_val': 0xFF4CAF50},
      {'name': 'Bonus', 'type': 'pemasukan', 'icon_code': 0xe263, 'color_val': 0xFF8BC34A},
      {'name': 'Investasi', 'type': 'pemasukan', 'icon_code': 0xe263, 'color_val': 0xFF00BCD4},
    ];
    for (var cat in initialCategories) {
      await db.insert('categories', cat);
    }

    // Seed 1 default account only (CASH, balance = 0)
    await db.insert('accounts', {
      'name': 'CASH',
      'type': 'Kas Pribadi',
      'balance': 0,
      'icon_code': 0xe4fc,
      'color_val': 0xFFFFCA28,
      'is_excluded': 0,
    });
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
  }

  // ─── Transactions CRUD ───────────────────────────────────────────────────

  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('transactions', row);
  }

  Future<List<Map<String, dynamic>>> readAllTransactions() async {
    final db = await instance.database;
    return await db.query('transactions', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> readTransactionsByMonth(
      int year, int month) async {
    final db = await instance.database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 1).toIso8601String();
    return await db.query(
      'transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );
  }

  Future<int> updateTransaction(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db
        .update('transactions', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db
        .delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> searchTransactions(String query) async {
    final db = await instance.database;
    return await db.query(
      'transactions',
      where: 'note LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'date DESC',
    );
  }

  // ─── Accounts CRUD ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> readAllAccounts() async {
    final db = await instance.database;
    return await db.query('accounts');
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

  Future<int> updateAccountBalance(String name, int amountChange) async {
    final db = await instance.database;
    final res =
        await db.query('accounts', where: 'name = ?', whereArgs: [name]);
    if (res.isNotEmpty) {
      final currentBalance = res.first['balance'] as int;
      return await db.update(
        'accounts',
        {'balance': currentBalance + amountChange},
        where: 'name = ?',
        whereArgs: [name],
      );
    }
    return 0;
  }

  Future<int> updateAccountBalanceById(int id, int amountChange) async {
    final db = await instance.database;
    final res = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) {
      final currentBalance = res.first['balance'] as int;
      return await db.update(
        'accounts',
        {'balance': currentBalance + amountChange},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    return 0;
  }

  // ─── Categories CRUD ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> readAllCategories() async {
    final db = await instance.database;
    return await db.query('categories');
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
    return await db.query(
      'budgets',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
    );
  }

  Future<int> upsertBudget(
      {required String category,
      required int amount,
      required int month,
      required int year}) async {
    final db = await instance.database;
    final existing = await db.query(
      'budgets',
      where: 'category = ? AND month = ? AND year = ?',
      whereArgs: [category, month, year],
    );
    if (existing.isNotEmpty) {
      return await db.update(
        'budgets',
        {'budget_amount': amount},
        where: 'category = ? AND month = ? AND year = ?',
        whereArgs: [category, month, year],
      );
    } else {
      return await db.insert('budgets', {
        'category': category,
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

  Future close() async {
    final db = await instance.database;
    db.close();
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
