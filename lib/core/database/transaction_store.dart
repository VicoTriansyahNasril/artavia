import 'package:sqflite/sqflite.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/widgets/commons/icon_registry.dart';

/// Every write that touches `transactions` goes through here so the account
/// balances change in the same DB transaction as the row (constitution IV).
///
/// The balance effect is always derived from the stored row, so callers never
/// have to pass amounts, fees or account ids back in to undo a transaction.
extension TransactionStore on DatabaseHelper {
  Future<int> addTransaction(Map<String, dynamic> row) async {
    final db = await database;
    return db.transaction((txn) => _insertWithEffect(txn, row));
  }

  /// Deletes a transaction and returns the stored row, so the deletion can
  /// be undone with [restoreTransaction] (FR-015).
  Future<Map<String, dynamic>?> deleteTransactionById(int id) async {
    final db = await database;
    return db.transaction((txn) => _deleteWithEffect(txn, id));
  }

  /// Puts a deleted row back under its original id and re-applies its
  /// balance effect.
  Future<void> restoreTransaction(Map<String, dynamic> snapshot) async {
    final db = await database;
    await db.transaction((txn) => _insertWithEffect(txn, snapshot));
  }

  /// Copies a transaction to now ("Duplikat ke hari ini"); returns the new id.
  Future<int?> duplicateToToday(int id) async {
    final db = await database;
    return db.transaction((txn) async {
      final rows =
          await txn.query('transactions', where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) return null;
      final copy = Map<String, dynamic>.of(rows.first)
        ..remove('id')
        ..remove('updated_at')
        ..['import_batch_id'] = null
        ..['date'] = DateTime.now().toIso8601String();
      return _insertWithEffect(txn, copy);
    });
  }

  /// Edits a transaction by reverting and removing the old row, then
  /// inserting [newRow]. Works even when the old account no longer exists.
  Future<int> replaceTransaction(int oldId, Map<String, dynamic> newRow) async {
    final db = await database;
    return db.transaction((txn) async {
      final old = await _deleteWithEffect(txn, oldId);
      return _insertWithEffect(txn, _keepBatch(old, newRow));
    });
  }

  /// Deletes an account with every transaction that touches it. Transfers
  /// are reverted first, so the other account's balance stays correct.
  /// Returns how many transactions were removed.
  Future<int> deleteAccountWithTransactions(int accountId) async {
    final db = await database;
    return db.transaction((txn) async {
      final rows = await txn.query('transactions',
          columns: ['id'],
          where: 'account_id = ? OR destination_account_id = ?',
          whereArgs: [accountId, accountId]);
      for (final r in rows) {
        await _deleteWithEffect(txn, r['id'] as int);
      }
      await txn.delete('accounts', where: 'id = ?', whereArgs: [accountId]);
      return rows.length;
    });
  }

  /// Deletes a category with its transactions (balances reverted); its
  /// budget links and recurring rules go via ON DELETE CASCADE, and budgets
  /// left without a category are pruned.
  Future<int> deleteCategoryWithTransactions(int categoryId) async {
    final db = await database;
    return db.transaction((txn) async {
      final rows = await txn.query('transactions',
          columns: ['id'], where: 'category_id = ?', whereArgs: [categoryId]);
      for (final r in rows) {
        await _deleteWithEffect(txn, r['id'] as int);
      }
      await txn.delete('categories', where: 'id = ?', whereArgs: [categoryId]);
      await DatabaseHelper.pruneEmptyBudgets(txn);
      return rows.length;
    });
  }

  /// Saves a transfer and, when [fee] > 0, its "Biaya admin" expense from
  /// the source account in one DB transaction (FR-012). With [replaceId]
  /// the old transfer is reverted and removed first (edit).
  Future<void> saveTransfer(
    Map<String, dynamic> transferRow, {
    int fee = 0,
    int? replaceId,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      final old =
          replaceId == null ? null : await _deleteWithEffect(txn, replaceId);
      await _insertWithEffect(txn, _keepBatch(old, transferRow));
      if (fee <= 0) return;
      await _insertWithEffect(txn, {
        'type': 'pengeluaran',
        'amount': fee,
        'category_id': await _feeCategoryId(txn),
        'note': 'Biaya admin transfer',
        'account_id': transferRow['account_id'],
        'date': transferRow['date'],
      });
    });
  }

  /// Inserts generated occurrences of a recurring rule and records the last
  /// generated date atomically, so a rule never fires twice for one date.
  Future<void> insertRecurringOccurrences(
    int ruleId,
    List<Map<String, dynamic>> rows,
    String lastRunDate,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final row in rows) {
        await _insertWithEffect(txn, row);
      }
      await txn.update('recurring_rules', {'last_run_date': lastRunDate},
          where: 'id = ?', whereArgs: [ruleId]);
    });
  }

  /// Imports already-validated rows that reference categories/accounts by
  /// name in one DB transaction, creating any missing category or account,
  /// and records them as an `import_batches` row (FR-034). The caller makes
  /// the safety copy of the DB file first. Returns the batch id.
  Future<int> importBatch(
    String fileName,
    List<Map<String, dynamic>> rows, {
    required int Function(int index) newCategoryColor,
  }) async {
    final db = await database;
    final createdAt = DateTime.now().toIso8601String();
    return db.transaction((txn) async {
      final batchId = await txn.insert('import_batches', {
        'file_name': fileName,
        'created_at': createdAt,
        'transaction_count': rows.length,
        'status': 'active',
      });
      final resolver = _NameResolver(txn, newCategoryColor);
      for (final r in rows) {
        final isTransfer = r['type'] == 'transfer';
        await _insertWithEffect(txn, {
          'type': r['type'],
          'amount': r['amount'],
          'category_id': isTransfer
              ? null
              : await resolver.category(
                  r['category'] as String, r['type'] as String),
          'account_id': await resolver.account(r['account'] as String),
          'destination_account_id': isTransfer
              ? await resolver.account(r['destination_account'] as String)
              : null,
          'note': r['note'] ?? '',
          'date': r['date'],
          'admin_fee': isTransfer ? r['admin_fee'] ?? 0 : 0,
          'admin_fee_type': isTransfer ? 'Pengirim' : null,
          'import_batch_id': batchId,
          // Equal to the batch time, so later edits are detectable.
          'updated_at': createdAt,
        });
      }
      return batchId;
    });
  }

  /// Undoes an import (≤ 7 days, status active): its transactions are
  /// removed through the balance-reverting path. With [keepEdited], rows
  /// changed after the import stay. Returns how many were removed.
  Future<int> cancelImport(int batchId, {bool keepEdited = false}) async {
    final db = await database;
    return db.transaction((txn) async {
      final batch = (await txn
              .query('import_batches', where: 'id = ?', whereArgs: [batchId]))
          .firstOrNull;
      if (batch == null || batch['status'] != 'active') return 0;
      final created = batch['created_at'] as String;
      final rows = await txn.query('transactions',
          columns: ['id'],
          where: keepEdited
              ? 'import_batch_id = ? AND (updated_at IS NULL OR updated_at <= ?)'
              : 'import_batch_id = ?',
          whereArgs: keepEdited ? [batchId, created] : [batchId]);
      for (final r in rows) {
        await _deleteWithEffect(txn, r['id'] as int);
      }
      await txn.update(
          'import_batches',
          {
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [batchId]);
      return rows.length;
    });
  }
}

/// Edits keep the row in its import batch (so "Batalkan impor" still finds
/// it and can tell it was changed).
Map<String, dynamic> _keepBatch(
        Map<String, dynamic>? old, Map<String, dynamic> row) =>
    old?['import_batch_id'] == null || row.containsKey('import_batch_id')
        ? row
        : {...row, 'import_batch_id': old!['import_batch_id']};

Future<int> _insertWithEffect(Transaction txn, Map<String, dynamic> row) async {
  final id = await txn.insert('transactions', {
    ...row,
    'updated_at': row['updated_at'] ?? DateTime.now().toIso8601String(),
  });
  await _applyBalanceEffect(txn, row, 1);
  return id;
}

Future<Map<String, dynamic>?> _deleteWithEffect(Transaction txn, int id) async {
  final rows =
      await txn.query('transactions', where: 'id = ?', whereArgs: [id]);
  if (rows.isEmpty) return null;
  await _applyBalanceEffect(txn, rows.first, -1);
  await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
  return Map<String, dynamic>.of(rows.first);
}

/// Applies (sign = 1) or reverts (sign = -1) a transaction's balance effect.
Future<void> _applyBalanceEffect(
    Transaction txn, Map<String, dynamic> row, int sign) async {
  final amount = row['amount'] as int;
  if (row['type'] != 'transfer') {
    final delta = row['type'] == 'pengeluaran' ? -amount : amount;
    await _adjustBalance(txn, row['account_id'] as int?, delta * sign);
    return;
  }
  final fee = row['admin_fee'] as int? ?? 0;
  final feeType = row['admin_fee_type'] as String?;
  final deduction = feeType == 'Pengirim' ? amount + fee : amount;
  final addition = feeType == 'Penerima' ? amount - fee : amount;
  await _adjustBalance(txn, row['account_id'] as int?, -deduction * sign);
  await _adjustBalance(
      txn, row['destination_account_id'] as int?, addition * sign);
}

Future<void> _adjustBalance(Transaction txn, int? accountId, int delta) async {
  if (accountId == null || delta == 0) return;
  await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?',
      [delta, accountId]);
}

const feeCategoryName = 'Biaya admin';

/// The expense category transfer fees are booked to, created on first use.
Future<int> _feeCategoryId(Transaction txn) async {
  final found = await txn.query('categories',
      where: 'LOWER(name) = ? AND type = ?',
      whereArgs: [feeCategoryName.toLowerCase(), 'pengeluaran'],
      limit: 1);
  if (found.isNotEmpty) return found.first['id'] as int;
  return txn.insert('categories', {
    'name': feeCategoryName,
    'type': 'pengeluaran',
    'icon_key': 'biaya_bank',
    'color_val': 0xFF8D94A3,
  });
}

/// Finds categories/accounts by (case-insensitive) name, creating them once.
class _NameResolver {
  final Transaction txn;
  final int Function(int index) newCategoryColor;
  final _accounts = <String, int>{};
  final _categories = <String, int>{};
  int _created = 0;

  _NameResolver(this.txn, this.newCategoryColor);

  Future<int> account(String name) async {
    final key = name.trim().toLowerCase();
    final cached = _accounts[key];
    if (cached != null) return cached;
    final found = await txn.query('accounts',
        where: 'LOWER(name) = ?', whereArgs: [key], limit: 1);
    final id = found.isNotEmpty
        ? found.first['id'] as int
        : await txn.insert('accounts', {
            'name': name.trim(),
            'type': 'Lainnya',
            'balance': 0,
            'currency_code': 'IDR',
            'is_excluded': 0,
            'icon_key': IconRegistry.accountTypeKey('Lainnya'),
          });
    return _accounts[key] = id;
  }

  Future<int> category(String name, String type) async {
    final key = '$type|${name.trim().toLowerCase()}';
    final cached = _categories[key];
    if (cached != null) return cached;
    final found = await txn.query('categories',
        where: 'LOWER(name) = ? AND type = ?',
        whereArgs: [name.trim().toLowerCase(), type],
        limit: 1);
    final id = found.isNotEmpty
        ? found.first['id'] as int
        : await txn.insert('categories', {
            'name': name.trim(),
            'type': type,
            'color_val': newCategoryColor(_created++),
            'icon_key': IconRegistry.fallbackKey,
          });
    return _categories[key] = id;
  }
}
