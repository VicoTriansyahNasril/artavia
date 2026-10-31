import 'package:flutter_test/flutter_test.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/database/transaction_store.dart';
import 'package:artavia/core/services/budget_import.dart';
import 'package:artavia/core/services/export_service.dart';
import 'package:artavia/core/services/import_service.dart';
import 'package:artavia/core/utils/finance_calc.dart';
import 'package:artavia/core/utils/xlsx_codec.dart';
import 'package:artavia/widgets/commons/common.dart';

import 'db_test_helper.dart';

final db = DatabaseHelper.instance;

/// Seeded expense categories: 1 Makanan, 2 Minuman, 3 Belanja.
void main() {
  setUpAll(initTestDatabaseFactory);
  setUp(() => db.resetDatabase());

  Future<List<Map<String, dynamic>>> october() =>
      db.readBudgetsByMonth(2026, 10);

  test('a named budget covers several categories and sums their spending',
      () async {
    await db.saveBudget(
        name: 'Makan & jajan',
        amount: 500000,
        categoryIds: {1, 2},
        month: 10,
        year: 2026);

    final b = (await october()).single;
    expect(b['name'], 'Makan & jajan');
    expect(b['category_ids'], [1, 2]);
    expect((b['categories'] as List).map((c) => c['name']),
        ['Makanan', 'Minuman']);

    final used = expenseByCategoryId([
      {'type': 'pengeluaran', 'amount': 300000, 'category_id': 1},
      {'type': 'pengeluaran', 'amount': 250000, 'category_id': 2},
      {'type': 'pengeluaran', 'amount': 99000, 'category_id': 3},
    ]);
    expect(budgetUsed(b, used), 550000);
    expect(budgetOfCategory(await october(), 2)?['id'], b['id']);
    expect(budgetOfCategory(await october(), 3), isNull);
  });

  test('a category moves out of another budget of the same period', () async {
    final first = await db.saveBudget(
        name: 'A', amount: 1, categoryIds: {1, 2}, month: 10, year: 2026);
    await db.saveBudget(
        name: 'B', amount: 1, categoryIds: {2}, month: 10, year: 2026);
    // Other periods keep their own links.
    await db.saveBudget(
        name: 'A', amount: 1, categoryIds: {2}, month: 11, year: 2026);

    final rows = await october();
    expect(rows.firstWhere((b) => b['id'] == first)['category_ids'], [1]);
    expect(rows.firstWhere((b) => b['name'] == 'B')['category_ids'], [2]);
    expect((await db.readBudgetsByMonth(2026, 11)).single['category_ids'], [2]);

    // Taking the last category of A removes A.
    await db.saveBudget(
        name: 'C', amount: 1, categoryIds: {1}, month: 10, year: 2026);
    expect((await october()).map((b) => b['name']), ['B', 'C']);
  });

  test('editing replaces name, limit and categories', () async {
    final id = await db.saveBudget(
        name: 'Lama', amount: 100, categoryIds: {1}, month: 10, year: 2026);
    await db.saveBudget(
        id: id,
        name: ' Baru ',
        amount: 200,
        categoryIds: {2, 3},
        month: 10,
        year: 2026);
    final b = (await october()).single;
    expect(b['id'], id);
    expect(b['name'], 'Baru');
    expect(b['budget_amount'], 200);
    expect(b['category_ids'], [2, 3]);
  });

  test('upsertBudget updates the budget holding the category or creates one',
      () async {
    await db.saveBudget(
        name: 'Makan', amount: 100, categoryIds: {1, 2}, month: 10, year: 2026);
    await db.upsertBudget(categoryId: 2, amount: 900, month: 10, year: 2026);
    await db.upsertBudget(categoryId: 3, amount: 50, month: 10, year: 2026);

    final rows = await october();
    expect(
        rows.map((b) => '${b['name']} ${b['budget_amount']} '
            '${b['category_ids']}'),
        ['Makan 900 [1, 2]', 'Belanja 50 [3]']);
  });

  test('deleting a category keeps a multi budget, drops an emptied one',
      () async {
    await db.saveBudget(
        name: 'Multi', amount: 1, categoryIds: {1, 2}, month: 10, year: 2026);
    await db.saveBudget(
        name: 'Solo', amount: 1, categoryIds: {3}, month: 10, year: 2026);

    await db.deleteCategory(1);
    await db.deleteCategoryWithTransactions(3);

    final rows = await october();
    expect(rows.single['name'], 'Multi');
    expect(rows.single['category_ids'], [2]);
    final raw = await (await db.database).query('budgets');
    expect(raw, hasLength(1), reason: 'no orphan budget rows left');
  });

  test('own icon and color are kept; null follows the categories', () async {
    final id = await db.saveBudget(
        name: 'Liburan',
        amount: 1,
        categoryIds: {1},
        month: 10,
        year: 2026,
        iconKey: 'kebun',
        colorVal: categoryPaletteValues[3]);
    var b = (await october()).single;
    expect(b['icon_key'], 'kebun');
    expect(b['color_val'], categoryPaletteValues[3]);

    // upsert (suggestions) keeps them.
    await db.upsertBudget(categoryId: 1, amount: 9, month: 10, year: 2026);
    expect((await october()).single['icon_key'], 'kebun');

    await db.saveBudget(
        id: id,
        name: 'Liburan',
        amount: 1,
        categoryIds: {1},
        month: 10,
        year: 2026);
    b = (await october()).single;
    expect(b['icon_key'], isNull);
    expect(b['color_val'], isNull);
  });

  group('copyBudgets', () {
    test('copies name, limit, categories, icon and color', () async {
      await db.saveBudget(
          name: 'Makan',
          amount: 500,
          categoryIds: {1, 2},
          month: 10,
          year: 2026,
          iconKey: 'kebun');
      final n = await db.copyBudgets(
          fromYear: 2026, fromMonth: 10, toYear: 2026, toMonth: 11);
      expect(n, 1);
      final b = (await db.readBudgetsByMonth(2026, 11)).single;
      expect(b['name'], 'Makan');
      expect(b['budget_amount'], 500);
      expect(b['category_ids'], [1, 2]);
      expect(b['icon_key'], 'kebun');
      expect((await october()).single['category_ids'], [1, 2],
          reason: 'source untouched');
    });

    test('skips taken names and categories; copying twice adds nothing',
        () async {
      await db.saveBudget(
          name: 'A', amount: 1, categoryIds: {1, 2}, month: 10, year: 2026);
      await db.saveBudget(
          name: 'B', amount: 1, categoryIds: {3}, month: 10, year: 2026);
      // December already budgets Minuman under another name, and has a "b".
      await db.saveBudget(
          name: 'X', amount: 1, categoryIds: {2}, month: 12, year: 2026);
      await db.saveBudget(
          name: 'b', amount: 1, categoryIds: {4}, month: 12, year: 2026);

      expect(
          await db.copyBudgets(
              fromYear: 2026, fromMonth: 10, toYear: 2026, toMonth: 12),
          1);
      final dec = await db.readBudgetsByMonth(2026, 12);
      expect(dec.firstWhere((b) => b['name'] == 'A')['category_ids'], [1]);
      expect(dec.firstWhere((b) => b['name'] == 'X')['category_ids'], [2]);
      expect(
          await db.copyBudgets(
              fromYear: 2026, fromMonth: 10, toYear: 2026, toMonth: 12),
          0);
    });
  });

  group('BudgetImport', () {
    test('parses the Ekspor layout and reports bad lines', () {
      final sheet = BudgetImport.parseRows([
        ['Bulan', 'Nama', 'Kategori', 'Batas', 'Ikon', 'Warna'],
        [
          '10/2026',
          'Makan & jajan',
          'Makanan, Minuman',
          '1.500.000',
          'kebun',
          'biru'
        ],
        ['2026-11', '', 'Kopi; kopi ;Belanja', 'Rp 200.000', 'nope', 'x'],
        ['13/2026', 'Salah', 'Makanan', '1000', '', ''],
        ['10/2026', 'Kosong', '', '1000', '', ''],
        ['10/2026', 'Nol', 'Makanan', '0', '', ''],
        ['10/2026', 'makan & JAJAN', 'Makanan', '1000', '', ''],
        ['', '', '', '', '', ''],
      ]);
      expect(sheet.rows, hasLength(2));
      final a = sheet.rows[0], b = sheet.rows[1];
      expect((a.year, a.month, a.name, a.amount),
          (2026, 10, 'Makan & jajan', 1500000));
      expect(a.categories, ['Makanan', 'Minuman']);
      expect(a.iconKey, 'kebun');
      expect(a.colorVal,
          categoryPaletteValues[categoryPaletteNames.indexOf('Biru')]);
      expect((b.year, b.month, b.name), (2026, 11, 'Kopi, Belanja'));
      expect(b.categories, ['Kopi', 'Belanja']);
      expect(b.iconKey, isNull);
      expect(b.colorVal, isNull);
      expect(sheet.problems, [
        'Baris 4: bulan tidak dikenali',
        'Baris 5: kategori kosong',
        'Baris 6: batas tidak valid',
        'Baris 7: anggaran "makan & JAJAN" ganda di bulan yang sama',
      ]);
    });

    test('older Bulan/Kategori/Batas layout works; missing columns throw', () {
      final sheet = BudgetImport.parseRows([
        ['Bulan', 'Kategori', 'Batas'],
        ['01/2027', 'Makanan', '500000'],
      ]);
      expect(sheet.rows.single.name, 'Makanan');
      expect(
          () => BudgetImport.parseRows([
                ['Bulan', 'Nama'],
                ['01/2027', 'x'],
              ]),
          throwsA(isA<ImportFileError>()));
    });

    test('export → import round trip, creating unknown categories', () async {
      await db.saveBudget(
          name: 'Makan & jajan',
          amount: 750000,
          categoryIds: {1, 2},
          month: 10,
          year: 2026,
          iconKey: 'kebun',
          colorVal: categoryPaletteValues[7]);
      final sheets = ExportService.buildSheets(
        parts: {ExportPart.budgets},
        transactions: const [],
        accounts: const [],
        categories: const [],
        budgets: await db.readAllBudgets(),
      );
      final bytes = XlsxCodec.encode(sheets);
      final parsed = BudgetImport.parseFile('artavia.xlsx', bytes);
      expect(parsed.problems, isEmpty);

      await db.resetDatabase();
      final result = await db.importBudgets([
        ...parsed.rows,
        BudgetImport.parseRows([
          ['Bulan', 'Kategori', 'Batas'],
          ['10/2026', 'Kopi Senja', '50000'],
        ]).rows.single,
      ]);
      expect((result.created, result.updated, result.newCategories), (2, 0, 1));
      final rows = await october();
      final b = rows.firstWhere((b) => b['name'] == 'Makan & jajan');
      expect(b['budget_amount'], 750000);
      expect(b['category_ids'], [1, 2]);
      expect(b['icon_key'], 'kebun');
      expect(b['color_val'], categoryPaletteValues[7]);
      final kopi = rows.firstWhere((b) => b['name'] == 'Kopi Senja');
      final cat = (kopi['categories'] as List).single;
      expect(cat['type'], 'pengeluaran');

      // Importing again updates by name instead of duplicating.
      final again = await db.importBudgets(parsed.rows);
      expect((again.created, again.updated, again.newCategories), (0, 1, 0));
      expect(await october(), hasLength(2));
    });
  });
}
