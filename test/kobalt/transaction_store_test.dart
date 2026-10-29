import 'package:flutter_test/flutter_test.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/database/transaction_store.dart';

import 'db_test_helper.dart';

final db = DatabaseHelper.instance;

Future<int> _balance(int id) async =>
    (await db.readAllAccounts()).firstWhere((a) => a['id'] == id)['balance']
        as int;

void main() {
  late int bca, gopay;

  setUpAll(initTestDatabaseFactory);

  setUp(() async {
    await db.resetDatabase();
    bca = await db
        .insertAccount({'name': 'BCA', 'type': 'Bank', 'balance': 1000000});
    gopay = await db.insertAccount(
        {'name': 'GoPay', 'type': 'Dompet Digital', 'balance': 0});
  });

  test('delete returns a snapshot; restore brings back row id and balance',
      () async {
    final id = await db.addTransaction({
      'type': 'pengeluaran',
      'amount': 45000,
      'category_id': 1,
      'note': 'Makan siang',
      'account_id': bca,
      'date': '2026-10-29T12:30:00.000',
    });
    expect(await _balance(bca), 955000);

    final snapshot = await db.deleteTransactionById(id);
    expect(snapshot?['id'], id);
    expect(await _balance(bca), 1000000);
    expect(await db.readAllTransactions(), isEmpty);

    await db.restoreTransaction(snapshot!);
    final rows = await db.readAllTransactions();
    expect(rows.single['id'], id);
    expect(rows.single['note'], 'Makan siang');
    expect(await _balance(bca), 955000);
  });

  test('deleting a missing id returns null', () async {
    expect(await db.deleteTransactionById(999), isNull);
  });

  test('duplicateToToday copies a transfer with its balance effect', () async {
    final id = await db.addTransaction({
      'type': 'transfer',
      'amount': 100000,
      'note': '',
      'account_id': bca,
      'destination_account_id': gopay,
      'date': '2026-01-01T08:00:00.000',
    });
    final copyId = await db.duplicateToToday(id);
    expect(copyId, isNot(id));
    expect(await _balance(bca), 800000);
    expect(await _balance(gopay), 200000);
    final copy =
        (await db.readAllTransactions()).firstWhere((r) => r['id'] == copyId);
    final date = DateTime.parse(copy['date'] as String);
    final now = DateTime.now();
    expect(DateTime(date.year, date.month, date.day),
        DateTime(now.year, now.month, now.day));
    expect(copy['updated_at'], isNotNull);
  });
}
