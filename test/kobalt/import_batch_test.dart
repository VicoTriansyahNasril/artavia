import 'package:flutter_test/flutter_test.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/database/transaction_store.dart';
import 'package:artavia/core/services/export_service.dart';
import 'package:artavia/core/services/import_service.dart';
import 'package:artavia/core/utils/xlsx_codec.dart';

import 'db_test_helper.dart';

final db = DatabaseHelper.instance;

Future<int> _balance(String name) async =>
    (await db.readAllAccounts()).firstWhere((a) => a['name'] == name)['balance']
        as int;

List<Map<String, dynamic>> _rows() => [
      {
        'type': 'pengeluaran',
        'amount': 45000,
        'category': 'Makanan',
        'account': 'BCA',
        'note': 'Makan siang',
        'date': '2026-10-01T12:30:00.000',
      },
      {
        'type': 'pemasukan',
        'amount': 500000,
        'category': 'Freelance',
        'account': 'BCA',
        'note': '',
        'date': '2026-10-02T09:00:00.000',
      },
      {
        'type': 'transfer',
        'amount': 100000,
        'account': 'BCA',
        'destination_account': 'GoPay',
        'admin_fee': 0,
        'note': 'Isi saldo',
        'date': '2026-10-03T08:00:00.000',
      },
    ];

void main() {
  setUpAll(initTestDatabaseFactory);

  setUp(() async {
    await db.resetDatabase();
    await db.insertAccount({'name': 'BCA', 'type': 'Bank', 'balance': 1000000});
  });

  test('import creates a batch, new names, and balance effects', () async {
    final id = await db.importBatch('mutasi.xlsx', _rows(),
        newCategoryColor: (_) => 0xFF5FBF8F);
    expect(await _balance('BCA'), 1000000 - 45000 + 500000 - 100000);
    expect(await _balance('GoPay'), 100000);
    final batch = (await db.readImportBatches()).single;
    expect(batch['id'], id);
    expect(batch['remaining'], 3);
    expect(batch['edited'], 0);
    expect(batch['status'], 'active');
    final cats = await db.readAllCategories();
    expect(cats.any((c) => c['name'] == 'Freelance'), isTrue);
  });

  test('cancel keeps edited rows when asked, and reverts balances', () async {
    final id = await db.importBatch('mutasi.xlsx', _rows(),
        newCategoryColor: (_) => 0xFF5FBF8F);
    final expense = (await db.readAllTransactions())
        .firstWhere((t) => t['type'] == 'pengeluaran');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await db.replaceTransaction(expense['id'] as int, {
      'type': 'pengeluaran',
      'amount': 50000,
      'category_id': expense['category_id'],
      'note': 'Makan siang (diubah)',
      'account_id': expense['account_id'],
      'date': expense['date'],
    });
    expect((await db.readImportBatches()).single['edited'], 1);

    final removed = await db.cancelImport(id, keepEdited: true);
    expect(removed, 2);
    final left = await db.readAllTransactions();
    expect(left.single['note'], 'Makan siang (diubah)');
    expect(await _balance('BCA'), 1000000 - 50000);
    expect(await _balance('GoPay'), 0);
    expect((await db.readImportBatches()).single['status'], 'cancelled');
    expect(await db.cancelImport(id), 0, reason: 'already cancelled');
  });

  test('export → import of the same data is all duplicates (SC-007)', () async {
    await db.importBatch('awal.xlsx', _rows(),
        newCategoryColor: (_) => 0xFF5FBF8F);
    final existing = await db.readAllTransactions();
    final sheets = ExportService.buildSheets(
      parts: {ExportPart.transactions},
      transactions: existing,
      accounts: const [],
      categories: const [],
      budgets: const [],
    );
    final file =
        ImportService.parseImportFile('artavia.xlsx', XlsxCodec.encode(sheets));
    final mapping = ImportService.guessMapping(file.headers);
    final preview = ImportService.buildPreview(
      file,
      mapping,
      order: DateOrder.dmy,
      thousandSep: '.',
      existingKeys: ImportService.keysOf(existing),
      existingCategories: const {},
      existingAccounts: const {},
    );
    expect(preview.problems, isEmpty);
    expect(preview.ready, isEmpty);
    expect(preview.duplicates.length, 3);
  });
}
