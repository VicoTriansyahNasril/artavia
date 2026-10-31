import 'dart:convert';
import 'dart:typed_data';

import 'package:artavia/core/models/budget_import_row.dart';
import 'package:artavia/core/services/import_service.dart';
import 'package:artavia/core/utils/csv_codec.dart';
import 'package:artavia/core/utils/xlsx_codec.dart';
import 'package:artavia/widgets/commons/common.dart';

/// Budgets parsed from a file, plus the lines that were skipped.
class BudgetSheet {
  final List<BudgetImportRow> rows;

  /// "Baris 4: batas tidak valid" — one per skipped line.
  final List<String> problems;

  const BudgetSheet(this.rows, this.problems);
}

/// Reads the "Anggaran" sheet written by Ekspor (Bulan, Nama, Kategori,
/// Batas, Ikon, Warna) — also the older Bulan/Kategori/Batas layout and a
/// CSV with the same headers.
class BudgetImport {
  static const sheetName = 'Anggaran';

  static BudgetSheet parseFile(String name, Uint8List bytes) {
    if (bytes.length > ImportService.maxBytes) {
      throw const ImportFileError('File lebih dari 20 MB');
    }
    final lower = name.toLowerCase();
    final List<List<String>> rows;
    if (lower.endsWith('.xlsx')) {
      final sheets = XlsxCodec.decode(bytes);
      final sheet = sheets[sheetName] ??
          sheets.values.where((r) => _columns(r).isComplete).firstOrNull;
      if (sheet == null) {
        throw const ImportFileError('Tidak ada sheet "Anggaran" di file ini');
      }
      rows = sheet;
    } else if (lower.endsWith('.csv') || lower.endsWith('.txt')) {
      rows = decodeCsv(utf8.decode(bytes, allowMalformed: true));
    } else {
      throw const ImportFileError('Pilih file .xlsx atau .csv');
    }
    return parseRows(rows);
  }

  static BudgetSheet parseRows(List<List<String>> rows) {
    if (rows.length < 2) {
      throw const ImportFileError('File tidak berisi baris anggaran');
    }
    final col = _columns(rows);
    if (!col.isComplete) {
      throw const ImportFileError('Kolom Bulan, Kategori dan Batas wajib ada');
    }
    String cell(List<String> r, int? i) =>
        i == null || i >= r.length ? '' : r[i].trim();

    final data = rows.skip(1).toList();
    final sep = ImportService.detectThousandSeparator(
        [for (final r in data) cell(r, col.amount)]);
    final result = <BudgetImportRow>[];
    final problems = <String>[];
    final seen = <String>{};
    for (var i = 0; i < data.length; i++) {
      final r = data[i];
      if (r.every((v) => v.trim().isEmpty)) continue;
      final line = i + 2;
      final period = parsePeriod(cell(r, col.month));
      if (period == null) {
        problems.add('Baris $line: bulan tidak dikenali');
        continue;
      }
      final categories = splitCategories(cell(r, col.categories));
      if (categories.isEmpty) {
        problems.add('Baris $line: kategori kosong');
        continue;
      }
      final amount = ImportService.parseAmount(cell(r, col.amount), sep);
      if (amount == null || amount <= 0) {
        problems.add('Baris $line: batas tidak valid');
        continue;
      }
      final named = cell(r, col.name);
      final name = named.isEmpty ? categories.join(', ') : named;
      if (!seen.add('${period.$1}-${period.$2}|${name.toLowerCase()}')) {
        problems.add('Baris $line: anggaran "$name" ganda di bulan yang sama');
        continue;
      }
      final icon = cell(r, col.icon);
      result.add(BudgetImportRow(
        year: period.$1,
        month: period.$2,
        name: name,
        categories: categories,
        amount: amount,
        iconKey: IconRegistry.contains(icon) ? icon : null,
        colorVal: colorByName(cell(r, col.color)),
      ));
    }
    return BudgetSheet(result, problems);
  }

  /// "10/2026", "10-2026", "2026-10", "2026/10" → (year, month).
  static (int, int)? parsePeriod(String raw) {
    final m =
        RegExp(r'^(\d{1,4})\s*[/\-.]\s*(\d{1,4})$').firstMatch(raw.trim());
    if (m == null) return null;
    final a = int.parse(m[1]!), b = int.parse(m[2]!);
    final (year, month) = m[1]!.length == 4 ? (a, b) : (b, a);
    if (year < 1970 || year > 9999 || month < 1 || month > 12) return null;
    return (year, month);
  }

  /// "Makanan, Minuman; Kopi" → unique names in order.
  static List<String> splitCategories(String raw) {
    final seen = <String>{};
    return [
      for (final p in raw.split(RegExp(r'[,;]')))
        if (p.trim().isNotEmpty && seen.add(p.trim().toLowerCase())) p.trim(),
    ];
  }

  /// Palette color by its Indonesian name ("Biru"), any case.
  static int? colorByName(String name) {
    final i = categoryPaletteNames
        .indexWhere((n) => n.toLowerCase() == name.trim().toLowerCase());
    return i < 0 ? null : categoryPaletteValues[i];
  }

  static _Columns _columns(List<List<String>> rows) {
    if (rows.isEmpty) return const _Columns();
    final h = [for (final v in rows.first) v.trim().toLowerCase()];
    int? find(List<String> names) {
      final i = h.indexWhere(names.contains);
      return i < 0 ? null : i;
    }

    return _Columns(
      month: find(['bulan', 'periode', 'month']),
      name: find(['nama', 'nama anggaran', 'anggaran', 'name']),
      categories: find(['kategori', 'category', 'categories']),
      amount: find(['batas', 'limit', 'nominal', 'jumlah', 'amount']),
      icon: find(['ikon', 'icon']),
      color: find(['warna', 'color']),
    );
  }
}

class _Columns {
  final int? month, name, categories, amount, icon, color;

  const _Columns({
    this.month,
    this.name,
    this.categories,
    this.amount,
    this.icon,
    this.color,
  });

  bool get isComplete => month != null && categories != null && amount != null;
}
