import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/services/import_service.dart';
import 'package:artavia/core/utils/csv_codec.dart';
import 'package:artavia/core/utils/xlsx_codec.dart';
import 'package:artavia/widgets/commons/common.dart';

enum ExportFormat { xlsx, csv }

enum ExportPart {
  transactions('Transaksi'),
  accounts('Rekening'),
  categories('Kategori'),
  budgets('Anggaran');

  final String sheet;
  const ExportPart(this.sheet);
}

/// `start <= date < end`; both null = all time.
class ExportRange {
  final String label;
  final DateTime? start;
  final DateTime? end;
  const ExportRange(this.label, [this.start, this.end]);

  bool contains(DateTime d) =>
      (start == null || !d.isBefore(start!)) &&
      (end == null || d.isBefore(end!));
}

/// Export (FR-034): Excel = one sheet per part, CSV = transactions only.
/// Amounts are numbers, dates `dd/MM/yyyy`; the transaction columns equal
/// [ImportService.exportHeaders] so a file can be imported back unchanged.
abstract final class ExportService {
  static final _date = DateFormat('dd/MM/yyyy');
  static final _time = DateFormat('HH:mm');

  static String typeLabel(String type) => switch (type) {
        'pemasukan' => 'Pemasukan',
        'transfer' => 'Transfer',
        _ => 'Pengeluaran',
      };

  // ─── Pure ────────────────────────────────────────────────────────────────

  static List<Object?> transactionCells(Map<String, dynamic> t) {
    final d = DateTime.parse(t['date'] as String);
    final transfer = t['type'] == 'transfer';
    return [
      _date.format(d),
      _time.format(d),
      typeLabel(t['type'] as String),
      t['amount'] as int,
      transfer ? '' : (t['categoryName'] as String? ?? ''),
      t['accountName'] as String? ?? '',
      transfer ? (t['destinationAccountName'] as String? ?? '') : '',
      transfer ? (t['admin_fee'] as int? ?? 0) : 0,
      t['note'] as String? ?? '',
    ];
  }

  static Map<String, List<List<Object?>>> buildSheets({
    required Set<ExportPart> parts,
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> accounts,
    required List<Map<String, dynamic>> categories,
    required List<Map<String, dynamic>> budgets,
  }) {
    final sheets = <String, List<List<Object?>>>{};
    if (parts.contains(ExportPart.transactions)) {
      final sorted = [...transactions]
        ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
      sheets[ExportPart.transactions.sheet] = [
        ImportService.exportHeaders,
        for (final t in sorted) transactionCells(t),
      ];
    }
    if (parts.contains(ExportPart.accounts)) {
      sheets[ExportPart.accounts.sheet] = [
        ['Nama', 'Jenis', 'Saldo', 'Mata uang', 'Dihitung', 'Diarsipkan'],
        for (final a in accounts)
          [
            a['name'],
            a['type'],
            a['balance'] as int? ?? 0,
            a['currency_code'] ?? 'IDR',
            a['is_excluded'] == 1 ? 'Tidak' : 'Ya',
            a['is_archived'] == 1 ? 'Ya' : 'Tidak',
          ],
      ];
    }
    if (parts.contains(ExportPart.categories)) {
      sheets[ExportPart.categories.sheet] = [
        ['Nama', 'Jenis', 'Warna', 'Ikon', 'Diarsipkan'],
        for (final c in categories)
          [
            c['name'],
            typeLabel(c['type'] as String),
            categoryPaletteNames[categoryPaletteValues.indexOf(
                nearestPaletteValue(c['color_val'] as int? ?? 0xFF8D94A3))],
            c['icon_key'] ?? '',
            c['is_archived'] == 1 ? 'Ya' : 'Tidak',
          ],
      ];
    }
    if (parts.contains(ExportPart.budgets)) {
      sheets[ExportPart.budgets.sheet] = [
        ['Bulan', 'Nama', 'Kategori', 'Batas', 'Ikon', 'Warna'],
        for (final b in budgets)
          [
            '${(b['month'] as int).toString().padLeft(2, '0')}/${b['year']}',
            b['name'] ?? '',
            [
              for (final c in b['categories'] as List? ?? const []) c['name'],
            ].join(', '),
            b['budget_amount'] as int,
            b['icon_key'] ?? '',
            if (b['color_val'] case final int v)
              categoryPaletteNames[
                  categoryPaletteValues.indexOf(nearestPaletteValue(v))]
            else
              '',
          ],
      ];
    }
    return sheets;
  }

  /// CSV text of the transactions sheet (with a BOM so Excel reads UTF-8).
  static String csvOf(Map<String, List<List<Object?>>> sheets) {
    final rows = sheets[ExportPart.transactions.sheet] ?? const [];
    return '﻿${encodeCsv([
          for (final r in rows) [for (final c in r) '${c ?? ''}'],
        ])}';
  }

  // ─── Data ────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> transactionsIn(
      ExportRange range) async {
    final db = DatabaseHelper.instance;
    final rows = range.start == null && range.end == null
        ? await db.readAllTransactions()
        : await db.readTransactionsByRange(
            range.start ?? DateTime(1970), range.end ?? DateTime(9999));
    return rows;
  }

  static Future<List<Map<String, dynamic>>> _budgets() =>
      DatabaseHelper.instance.readAllBudgets();

  static Future<Map<ExportPart, int>> counts(ExportRange range) async {
    final db = DatabaseHelper.instance;
    return {
      ExportPart.transactions: (await transactionsIn(range)).length,
      ExportPart.accounts: (await db.readAllAccounts()).length,
      ExportPart.categories: (await db.readAllCategories()).length,
      ExportPart.budgets: (await _budgets()).length,
    };
  }

  /// Writes the file into the temp folder and opens the share sheet.
  static Future<File> exportAndShare({
    required ExportFormat format,
    required ExportRange range,
    required Set<ExportPart> parts,
  }) async {
    final db = DatabaseHelper.instance;
    final sheets = buildSheets(
      parts: format == ExportFormat.csv ? {ExportPart.transactions} : parts,
      transactions: await transactionsIn(range),
      accounts: await db.readAllAccounts(),
      categories: await db.readAllCategories(),
      budgets: await _budgets(),
    );
    final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
    final name =
        'artavia-$stamp.${format == ExportFormat.xlsx ? 'xlsx' : 'csv'}';
    final bytes = format == ExportFormat.xlsx
        ? XlsxCodec.encode(sheets)
        : Uint8List.fromList(utf8.encode(csvOf(sheets)));
    final file = await _write(name, bytes);
    await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)], subject: 'Data Artavia (${range.label})'));
    return file;
  }

  /// "Unduh template": headers plus two example rows.
  static Future<void> shareTemplate() async {
    final bytes = XlsxCodec.encode({
      ExportPart.transactions.sheet: [
        ImportService.exportHeaders,
        [
          '01/10/2026',
          '12:30',
          'Pengeluaran',
          45000,
          'Makanan',
          'BCA',
          '',
          0,
          'Makan siang'
        ],
        [
          '01/10/2026',
          '08:00',
          'Transfer',
          100000,
          '',
          'BCA',
          'GoPay',
          2500,
          'Isi saldo'
        ],
      ],
    });
    final file = await _write('template-impor-artavia.xlsx', bytes);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  static Future<void> shareText(String name, String text) async {
    final file = await _write(name, Uint8List.fromList(utf8.encode(text)));
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  static Future<File> _write(String name, Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
