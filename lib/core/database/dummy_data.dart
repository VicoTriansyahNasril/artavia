import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'dart:math';

/// Set this to true to generate dummy data on database creation
const bool useDummyData = true;

class DummyDataGenerator {
  static Future<void> generate(Database db) async {
    final rand = Random();
    final now = DateTime.now();

    // 1. Generate additional dummy accounts
    final accounts = [
      {'name': 'Mandiri', 'type': 'Bank', 'balance': 5000000, 'currency_code': 'IDR', 'icon_code': null, 'icon_path': 'assets/keuangan/bank.png', 'color_val': 0xFF005EAA, 'is_excluded': 0},
      {'name': 'BCA', 'type': 'Bank', 'balance': 2500000, 'currency_code': 'IDR', 'icon_code': null, 'icon_path': 'assets/keuangan/bank.png', 'color_val': 0xFF005EAA, 'is_excluded': 0},
      {'name': 'Gopay', 'type': 'E-Wallet', 'balance': 300000, 'currency_code': 'IDR', 'icon_code': null, 'icon_path': 'assets/keuangan/dompet.png', 'color_val': 0xFF388E3C, 'is_excluded': 0},
    ];

    for (var acc in accounts) {
      await db.insert('accounts', acc);
    }

    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    // 2. Generate dummy transactions (concentrated around today and yesterday)
    // 50 transactions total
    for (int i = 0; i < 50; i++) {
      // 60% chance for today or yesterday, 40% chance for up to 30 days ago
      int daysAgo = 0;
      if (rand.nextDouble() < 0.6) {
        daysAgo = rand.nextInt(2); // 0 or 1
      } else {
        daysAgo = rand.nextInt(30) + 2;
      }
      
      final randomDate = now.subtract(Duration(days: daysAgo, hours: rand.nextInt(24), minutes: rand.nextInt(60)));
      
      final isExpense = rand.nextDouble() > 0.3; // 70% expense, 30% income
      // Categories: 1-11 are pengeluaran, 12-16 are pemasukan
      final categoryId = isExpense ? (rand.nextInt(11) + 1) : (rand.nextInt(5) + 12);
      final type = isExpense ? 'pengeluaran' : 'pemasukan';
      
      // Amount: 10k - 200k for expenses, 1M - 5M for income
      final amount = isExpense 
          ? ((rand.nextInt(20) + 1) * 10000) 
          : ((rand.nextInt(40) + 10) * 100000);
          
      final accountId = rand.nextInt(4) + 1; // 1 to 4
      
      final notes = isExpense ? [
        'Beli kebutuhan bulanan', 'Jajan sore', 'Isi bensin', 'Makan siang',
        'Bayar tagihan listrik', 'Nongkrong santai', 'Belanja online', 'Pulsa'
      ] : [
        'Gaji bulanan', 'Bonus proyek', 'Hasil investasi', 'Transferan teman'
      ];
      final note = notes[rand.nextInt(notes.length)];

      await db.insert('transactions', {
        'account_id': accountId,
        'category_id': categoryId,
        'amount': amount,
        'type': type,
        'note': note,
        'date': formatter.format(randomDate),
        'destination_account_id': null,
      });
    }

    // 3. Generate dummy budgets for the current month
    final budgetCategories = [1, 2, 3]; // Makanan, Minuman, Belanja
    for (var catId in budgetCategories) {
      await db.insert('budgets', {
        'category_id': catId,
        'budget_amount': (rand.nextInt(10) + 5) * 50000, // 250k - 700k
        'month': now.month,
        'year': now.year,
      });
    }
  }
}
