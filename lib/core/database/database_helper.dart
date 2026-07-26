import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:artavia/core/database/dummy_data.dart';

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
      version: 9,
      onConfigure: _onConfigure,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
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
  category_id INTEGER,
  note $textType,
  account_id INTEGER,
  destination_account_id INTEGER,
  date $textType,
  FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT,
  FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE RESTRICT,
  FOREIGN KEY (destination_account_id) REFERENCES accounts (id) ON DELETE RESTRICT
)
''');

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
  is_excluded INTEGER NOT NULL DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE categories (
  id $idType,
  name $textType,
  type $textType,
  icon_code INTEGER,
  icon_path TEXT,
  color_val INTEGER
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

    // Seed Categories
    final initialCategories = [
      // Pengeluaran
      {'name': 'Makanan', 'type': 'pengeluaran', 'icon_code': null, 'icon_path': 'assets/makanan/bowl.png', 'color_val': 0xFF4CAF50},
      {'name': 'Minuman', 'type': 'pengeluaran', 'icon_code': null, 'icon_path': 'assets/makanan/soft-drink.png', 'color_val': 0xFF8BC34A},
      {'name': 'Belanja', 'type': 'pengeluaran', 'icon_code': null, 'icon_path': 'assets/belanja/shopping-bag.png', 'color_val': 0xFFFF9800},
      {'name': 'Transportasi', 'type': 'pengeluaran', 'icon_code': null, 'icon_path': 'assets/transportasi/car.png', 'color_val': 0xFF9C27B0},
      {'name': 'Kesehatan', 'type': 'pengeluaran', 'icon_code': null, 'icon_path': 'assets/kesehatan/health-care.png', 'color_val': 0xFFF44336},
      {'name': 'Hiburan', 'type': 'pengeluaran', 'icon_code': null, 'icon_path': 'assets/hiburan/cinema.png', 'color_val': 0xFFE91E63},
      {'name': 'Pendidikan', 'type': 'pengeluaran', 'icon_code': null, 'icon_path': 'assets/pendidikan/education.png', 'color_val': 0xFF3F51B5},
      {'name': 'Olahraga', 'type': 'pengeluaran', 'icon_code': null, 'icon_path': 'assets/olahraga/sport.png', 'color_val': 0xFFFF5722},
      {'name': 'Liburan', 'type': 'pengeluaran', 'icon_code': null, 'icon_path': 'assets/berpergian/travel.png', 'color_val': 0xFF009688},
      {'name': 'Pribadi', 'type': 'pengeluaran', 'icon_code': null, 'icon_path': 'assets/pribadi/briefcase.png', 'color_val': 0xFF607D8B},
      {'name': 'Tagihan', 'type': 'pengeluaran', 'icon_code': null, 'icon_path': 'assets/pribadi/wifi.png', 'color_val': 0xFF795548},
      
      // Pemasukan
      {'name': 'Gaji', 'type': 'pemasukan', 'icon_code': null, 'icon_path': 'assets/keuangan/uang.png', 'color_val': 0xFF4CAF50},
      {'name': 'Bonus', 'type': 'pemasukan', 'icon_code': null, 'icon_path': 'assets/keuangan/coin.png', 'color_val': 0xFF8BC34A},
      {'name': 'Investasi', 'type': 'pemasukan', 'icon_code': null, 'icon_path': 'assets/keuangan/stock.png', 'color_val': 0xFF00BCD4},
      {'name': 'Bisnis', 'type': 'pemasukan', 'icon_code': null, 'icon_path': 'assets/pribadi/meeting.png', 'color_val': 0xFF2196F3},
      {'name': 'Tabungan', 'type': 'pemasukan', 'icon_code': null, 'icon_path': 'assets/keuangan/nabung.png', 'color_val': 0xFF009688},
    ];
    for (var cat in initialCategories) {
      await db.insert('categories', cat);
    }

    // Seed 1 default account only
    await db.insert('accounts', {
      'name': 'Kas Utama',
      'type': 'Kas Pribadi',
      'balance': 0,
      'icon_code': 0xe4fc,
      'icon_path': 'assets/keuangan/dompet.png',
      'color_val': 0xFF005EAA, // BMW Blue
      'is_excluded': 0,
    });

    if (useDummyData) {
      await DummyDataGenerator.generate(db);
    }
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
        await db.execute('ALTER TABLE transactions ADD COLUMN category_id INTEGER');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN account_id INTEGER');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN destination_account_id INTEGER');
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
  }

  // ─── Transactions CRUD ───────────────────────────────────────────────────

  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('transactions', row);
  }

  Future<List<Map<String, dynamic>>> readAllTransactions() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT t.*, c.name as categoryName, c.icon_code as categoryIconCode, c.icon_path as categoryIconPath, c.color_val as categoryColorVal, 
             a.name as accountName, da.name as destinationAccountName 
      FROM transactions t 
      LEFT JOIN categories c ON t.category_id = c.id 
      LEFT JOIN accounts a ON t.account_id = a.id 
      LEFT JOIN accounts da ON t.destination_account_id = da.id 
      ORDER BY t.date DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> readTransactionsByMonth(
      int year, int month) async {
    final db = await instance.database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 1).toIso8601String();
    return await db.rawQuery('''
      SELECT t.*, c.name as categoryName, c.icon_code as categoryIconCode, c.icon_path as categoryIconPath, c.color_val as categoryColorVal, 
             a.name as accountName, da.name as destinationAccountName
      FROM transactions t 
      LEFT JOIN categories c ON t.category_id = c.id 
      LEFT JOIN accounts a ON t.account_id = a.id 
      LEFT JOIN accounts da ON t.destination_account_id = da.id 
      WHERE t.date >= ? AND t.date < ?
      ORDER BY t.date DESC
    ''', [startDate, endDate]);
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

  Future<void> insertTransactionWithBalanceUpdate(Map<String, dynamic> row, int accountId, int balanceChange) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert('transactions', row);
      final res = await txn.query('accounts', where: 'id = ?', whereArgs: [accountId]);
      if (res.isNotEmpty) {
        final currentBalance = res.first['balance'] as int;
        await txn.update(
          'accounts',
          {'balance': currentBalance + balanceChange},
          where: 'id = ?',
          whereArgs: [accountId],
        );
      }
    });
  }

  Future<void> insertTransferWithBalanceUpdate(Map<String, dynamic> row, int sourceAccountId, int destAccountId, int amount) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert('transactions', row);
      
      final sourceRes = await txn.query('accounts', where: 'id = ?', whereArgs: [sourceAccountId]);
      if (sourceRes.isNotEmpty) {
        final currentBalance = sourceRes.first['balance'] as int;
        await txn.update(
          'accounts',
          {'balance': currentBalance - amount},
          where: 'id = ?',
          whereArgs: [sourceAccountId],
        );
      }
      
      final destRes = await txn.query('accounts', where: 'id = ?', whereArgs: [destAccountId]);
      if (destRes.isNotEmpty) {
        final currentBalance = destRes.first['balance'] as int;
        await txn.update(
          'accounts',
          {'balance': currentBalance + amount},
          where: 'id = ?',
          whereArgs: [destAccountId],
        );
      }
    });
  }

  Future<void> deleteTransactionWithBalanceUpdate(int transactionId, int? accountId, int? destinationAccountId, int amount, bool isExpense, bool isTransfer) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      if (isTransfer && accountId != null && destinationAccountId != null) {
        final sourceRes = await txn.query('accounts', where: 'id = ?', whereArgs: [accountId]);
        if (sourceRes.isNotEmpty) {
          final currentBalance = sourceRes.first['balance'] as int;
          await txn.update('accounts', {'balance': currentBalance + amount}, where: 'id = ?', whereArgs: [accountId]);
        }
        final destRes = await txn.query('accounts', where: 'id = ?', whereArgs: [destinationAccountId]);
        if (destRes.isNotEmpty) {
          final currentBalance = destRes.first['balance'] as int;
          await txn.update('accounts', {'balance': currentBalance - amount}, where: 'id = ?', whereArgs: [destinationAccountId]);
        }
      } else if (accountId != null) {
        final multiplier = isExpense ? 1 : -1;
        final res = await txn.query('accounts', where: 'id = ?', whereArgs: [accountId]);
        if (res.isNotEmpty) {
          final currentBalance = res.first['balance'] as int;
          await txn.update('accounts', {'balance': currentBalance + (amount * multiplier)}, where: 'id = ?', whereArgs: [accountId]);
        }
      }
      await txn.delete('transactions', where: 'id = ?', whereArgs: [transactionId]);
    });
  }

  Future<List<Map<String, dynamic>>> searchTransactions(String query) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT t.*, c.name as categoryName, c.icon_code as categoryIconCode, c.icon_path as categoryIconPath, c.color_val as categoryColorVal, 
             a.name as accountName, da.name as destinationAccountName
      FROM transactions t 
      LEFT JOIN categories c ON t.category_id = c.id 
      LEFT JOIN accounts a ON t.account_id = a.id 
      LEFT JOIN accounts da ON t.destination_account_id = da.id 
      WHERE t.note LIKE ? OR c.name LIKE ?
      ORDER BY t.date DESC
    ''', ['%$query%', '%$query%']);
  }

  // ─── Accounts CRUD ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> readAllAccounts() async {
    final db = await instance.database;
    return await db.query('accounts', orderBy: 'type ASC, name ASC');
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
    return await db.rawQuery('''
      SELECT b.*, c.name as categoryName, c.type as categoryType, c.icon_code as categoryIconCode, c.icon_path as categoryIconPath, c.color_val as categoryColorVal 
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
