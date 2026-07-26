import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:artavia/core/database/database_helper.dart';

void main() {
  // Initialize sqflite ffi for desktop/testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper Extreme Tests', () {
    setUp(() async {
      // Reset db before each test
      await DatabaseHelper.instance.resetDatabase();
    });

    tearDown(() async {
      await DatabaseHelper.instance.close();
    });

    test('Insert and Read Transaction with SQL injection chars', () async {
      const note = "Makan siang \n \t DROP TABLE transactions; -- 😜";
      final row = {
        'type': 'pengeluaran',
        'amount': 15000,
        'category_id': 1,
        'note': note,
        'account_id': 1,
        'date': DateTime.now().toIso8601String(),
      };

      final id = await DatabaseHelper.instance.insertTransaction(row);
      expect(id, isPositive);

      final data = await DatabaseHelper.instance.readAllTransactions();
      expect(data.length, 1);
      expect(data.first['note'], note); // Should not crash, SQL injection should fail since we use parameterized queries.
    });

    test('Negative amounts in transactions', () async {
      // Typically amounts should be positive, if the app doesn't validate at DB level, we check what happens.
      final row = {
        'type': 'pengeluaran',
        'amount': -50000,
        'category_id': 2,
        'note': 'Refund?',
        'account_id': 1,
        'date': DateTime.now().toIso8601String(),
      };
      
      final id = await DatabaseHelper.instance.insertTransaction(row);
      expect(id, isPositive);
      
      final data = await DatabaseHelper.instance.readAllTransactions();
      expect(data.first['amount'], -50000); 
    });

    test('Update account balance', () async {
      // Ensure the initial account CASH exists
      final accounts = await DatabaseHelper.instance.readAllAccounts();
      expect(accounts.length, 1);
      expect(accounts.first['name'], 'CASH');
      expect(accounts.first['balance'], 0);

      // Add 10000
      await DatabaseHelper.instance.updateAccountBalanceById(1, 10000);
      var acc = await DatabaseHelper.instance.readAllAccounts();
      expect(acc.first['balance'], 10000);

      // Subtract 20000
      await DatabaseHelper.instance.updateAccountBalanceById(1, -20000);
      acc = await DatabaseHelper.instance.readAllAccounts();
      expect(acc.first['balance'], -10000); // Balance goes negative, which might be a bug if the app doesn't prevent it!
    });
    
    test('Upsert Budget duplicate month/year', () async {
      await DatabaseHelper.instance.upsertBudget(categoryId: 1, amount: 50000, month: 10, year: 2023);
      await DatabaseHelper.instance.upsertBudget(categoryId: 1, amount: 80000, month: 10, year: 2023);
      
      final budgets = await DatabaseHelper.instance.readBudgetsByMonth(2023, 10);
      expect(budgets.length, 1);
      expect(budgets.first['budget_amount'], 80000);
    });

    test('Saving and fetching settings', () async {
      await DatabaseHelper.instance.saveSetting('theme', 'dark');
      final val1 = await DatabaseHelper.instance.getSetting('theme');
      expect(val1, 'dark');

      // Overwrite setting
      await DatabaseHelper.instance.saveSetting('theme', 'light');
      final val2 = await DatabaseHelper.instance.getSetting('theme');
      expect(val2, 'light');

      // Non-existent setting
      final val3 = await DatabaseHelper.instance.getSetting('non-existent');
      expect(val3, isNull);
    });
  });
}
