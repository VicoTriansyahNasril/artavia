import 'package:sqflite/sqflite.dart';
import 'package:artavia/core/database/database_helper.dart';

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

  Future<void> deleteTransactionById(int id) async {
    final db = await database;
    await db.transaction((txn) => _deleteWithEffect(txn, id));
  }

  /// Edits a transaction by reverting and removing the old row, then
  /// inserting [newRow]. Works even when the old account no longer exists.
  Future<int> replaceTransaction(int oldId, Map<String, dynamic> newRow) async {
    final db = await database;
    return db.transaction((txn) async {
      await _deleteWithEffect(txn, oldId);
      return _insertWithEffect(txn, newRow);
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
  /// name, creating any missing category or account. All-or-nothing.
  Future<int> importTransactions(
    List<Map<String, dynamic>> rows, {
    required int Function(int index) newCategoryColor,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
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
        });
      }
      return rows.length;
    });
  }
}

Future<int> _insertWithEffect(Transaction txn, Map<String, dynamic> row) async {
  final id = await txn.insert('transactions', row);
  await _applyBalanceEffect(txn, row, 1);
  return id;
}

Future<void> _deleteWithEffect(Transaction txn, int id) async {
  final rows =
      await txn.query('transactions', where: 'id = ?', whereArgs: [id]);
  if (rows.isEmpty) return;
  await _applyBalanceEffect(txn, rows.first, -1);
  await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
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
          });
    return _categories[key] = id;
  }
}
