import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:artavia/core/database/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Keterkaitan (Integration) & Anomali Edge Cases', () {
    setUp(() async {
      await DatabaseHelper.instance.resetDatabase();
    });

    tearDown(() async {
      await DatabaseHelper.instance.close();
    });

    test('Fix: Mengganti nama akun tidak lagi membuat transaksi yatim (Orphaned)', () async {
      // 1. Pastikan akun CASH ada
      var accounts = await DatabaseHelper.instance.readAllAccounts();
      final accountId = accounts.first['id'] as int;

      // 2. Buat transaksi pakai akun CASH
      final row = {
        'type': 'pengeluaran',
        'amount': 20000,
        'category_id': 1,
        'note': 'Nasi padang',
        'account_id': accountId,
        'date': DateTime.now().toIso8601String(),
      };
      await DatabaseHelper.instance.insertTransaction(row);

      // 3. Kita ubah nama akun dari CASH menjadi DOMPET
      await DatabaseHelper.instance.updateAccount(accountId, {'name': 'DOMPET'});

      // 4. Baca transaksi kembali
      final transactions = await DatabaseHelper.instance.readAllTransactions();
      
      // KARENA JOIN, akun akan otomatis ter-resolve menjadi DOMPET
      expect(transactions.first['accountName'], 'DOMPET'); 
      
      final updatedAccounts = await DatabaseHelper.instance.readAllAccounts();
      expect(updatedAccounts.first['name'], 'DOMPET');
    });

    test('Fix: Menghapus kategori tidak lagi meninggalkan data usang karena FOREIGN KEY RESTRICT', () async {
      final row = {
        'type': 'pengeluaran',
        'amount': 50000,
        'category_id': 1,
        'note': 'Makanan kucing',
        'account_id': 1,
        'date': DateTime.now().toIso8601String(),
      };
      await DatabaseHelper.instance.insertTransaction(row);

      // Mencoba menghapus kategori ID 1 akan gagal/melempar error karena FOREIGN KEY constraints
      expect(
        () async => await DatabaseHelper.instance.deleteCategory(1),
        throwsException
      );
    });
  });
}
