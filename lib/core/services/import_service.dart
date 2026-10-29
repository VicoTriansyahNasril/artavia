import 'dart:convert';
import 'dart:typed_data';

import 'package:artavia/core/utils/csv_codec.dart';
import 'package:artavia/core/utils/xlsx_codec.dart';

/// Pure import pipeline (FR-034/035, research R8):
/// `parseImportFile → guessMapping → detect date order / thousand separator
/// → buildPreview (ready / duplicates / problems / new names)`.
/// Nothing here touches the database; commit lives in TransactionStore.

enum ImportField {
  date('Tanggal', true),
  time('Jam', false),
  amount('Jumlah', true),
  type('Jenis', false),
  category('Kategori', false),
  account('Rekening', false),
  destination('Rekening tujuan', false),
  note('Catatan', false),
  fee('Biaya admin', false);

  final String label;
  final bool required;
  const ImportField(this.label, this.required);
}

enum DateOrder {
  dmy('31/12/2026'),
  mdy('12/31/2026'),
  ymd('2026-12-31');

  final String example;
  const DateOrder(this.example);
}

class ImportFileError implements Exception {
  final String message;
  const ImportFileError(this.message);
  @override
  String toString() => message;
}

class ParsedFile {
  final String name;
  final int sizeBytes;
  final List<String> headers;
  final List<List<String>> rows;

  const ParsedFile(this.name, this.sizeBytes, this.headers, this.rows);
}

class ImportRow {
  /// 1-based line in the file (header = line 1).
  final int line;
  final DateTime date;
  final String type;
  final int amount;
  final String? category;
  final String account;
  final String? destination;
  final String note;
  final int fee;

  const ImportRow({
    required this.line,
    required this.date,
    required this.type,
    required this.amount,
    required this.category,
    required this.account,
    required this.destination,
    required this.note,
    required this.fee,
  });

  ImportRow rename({String? category, String? account, String? destination}) =>
      ImportRow(
        line: line,
        date: date,
        type: type,
        amount: amount,
        category: category ?? this.category,
        account: account ?? this.account,
        destination: destination ?? this.destination,
        note: note,
        fee: fee,
      );
}

class ImportProblem {
  final int line;
  final String reason;
  final List<String> raw;
  const ImportProblem(this.line, this.reason, this.raw);
}

/// A name in the file that does not exist yet. [type] is set for
/// categories ('pengeluaran' / 'pemasukan').
class NewName {
  final String name;
  final String? type;
  const NewName(this.name, [this.type]);

  String get key => '${type ?? 'account'}|${name.toLowerCase()}';
}

class ImportPreview {
  final List<ImportRow> ready;
  final List<ImportRow> duplicates;
  final List<ImportProblem> problems;
  final List<NewName> newCategories;
  final List<NewName> newAccounts;

  const ImportPreview({
    required this.ready,
    required this.duplicates,
    required this.problems,
    required this.newCategories,
    required this.newAccounts,
  });
}

abstract final class ImportService {
  static const maxBytes = 20 * 1024 * 1024;
  static const maxRows = 50000;

  /// Same column titles as the export, so an Artavia file maps itself.
  static const exportHeaders = [
    'Tanggal',
    'Jam',
    'Jenis',
    'Jumlah',
    'Kategori',
    'Rekening',
    'Rekening tujuan',
    'Biaya admin',
    'Catatan',
  ];

  static const _synonyms = <ImportField, List<String>>{
    ImportField.date: ['tanggal', 'tgl', 'date', 'waktu', 'tanggal transaksi'],
    ImportField.time: ['jam', 'time', 'pukul'],
    ImportField.amount: [
      'jumlah',
      'nominal',
      'amount',
      'nilai',
      'total',
      'harga',
      'debit/kredit'
    ],
    ImportField.type: ['jenis', 'tipe', 'type', 'kategori transaksi'],
    ImportField.category: ['kategori', 'category', 'kelompok'],
    ImportField.account: [
      'rekening',
      'akun',
      'account',
      'dompet',
      'sumber',
      'rekening asal'
    ],
    ImportField.destination: ['rekening tujuan', 'tujuan', 'ke', 'to'],
    ImportField.note: [
      'catatan',
      'keterangan',
      'note',
      'notes',
      'deskripsi',
      'description',
      'memo'
    ],
    ImportField.fee: ['biaya admin', 'admin', 'fee', 'biaya'],
  };

  // ─── File ────────────────────────────────────────────────────────────────

  static ParsedFile parseImportFile(String name, Uint8List bytes) {
    if (bytes.length > maxBytes) {
      throw const ImportFileError('File lebih dari 20 MB');
    }
    final lower = name.toLowerCase();
    List<List<String>> rows;
    if (lower.endsWith('.xlsx')) {
      final sheets = XlsxCodec.decode(bytes);
      if (sheets.isEmpty) throw const ImportFileError('File Excel kosong');
      rows = sheets['Transaksi'] ?? sheets.values.first;
    } else if (lower.endsWith('.csv') || lower.endsWith('.txt')) {
      rows = decodeCsv(utf8.decode(bytes, allowMalformed: true));
    } else {
      throw const ImportFileError('Pilih file .xlsx atau .csv');
    }
    if (rows.length < 2) {
      throw const ImportFileError('File tidak berisi baris data');
    }
    if (rows.length - 1 > maxRows) {
      throw const ImportFileError('File lebih dari 50.000 baris');
    }
    final headers = rows.first.map((h) => h.trim()).toList();
    return ParsedFile(name, bytes.length, headers, rows.skip(1).toList());
  }

  /// Best guess per field from header names (each column used once).
  static Map<ImportField, int> guessMapping(List<String> headers) {
    final norm = headers.map((h) => h.trim().toLowerCase()).toList();
    final used = <int>{};
    final result = <ImportField, int>{};
    // Exact matches first, then "contains", so "Rekening tujuan" is not
    // taken by Rekening.
    for (final exact in [true, false]) {
      for (final field in ImportField.values) {
        if (result.containsKey(field)) continue;
        for (final syn in _synonyms[field]!) {
          final i = List.generate(norm.length, (i) => i).firstWhere(
              (i) =>
                  !used.contains(i) &&
                  (exact ? norm[i] == syn : norm[i].contains(syn)),
              orElse: () => -1);
          if (i >= 0) {
            result[field] = i;
            used.add(i);
            break;
          }
        }
      }
    }
    return result;
  }

  static List<String> missingRequired(Map<ImportField, int?> mapping) => [
        for (final f in ImportField.values)
          if (f.required && mapping[f] == null) f.label,
      ];

  // ─── Detection ───────────────────────────────────────────────────────────

  static final _dateParts =
      RegExp(r'^(\d{1,4})[\/\-.](\d{1,2})[\/\-.](\d{1,4})');

  static DateOrder detectDateOrder(Iterable<String> samples) {
    var dmy = 0, mdy = 0, ymd = 0;
    for (final s in samples) {
      final m = _dateParts.firstMatch(s.trim());
      if (m == null) continue;
      final a = int.parse(m[1]!), b = int.parse(m[2]!);
      if (m[1]!.length == 4) {
        ymd++;
      } else if (a > 12) {
        dmy++;
      } else if (b > 12) {
        mdy++;
      }
    }
    if (ymd > dmy && ymd > mdy) return DateOrder.ymd;
    return mdy > dmy ? DateOrder.mdy : DateOrder.dmy;
  }

  /// '.' (Indonesian, "1.500.000") or ',' ("1,500,000").
  static String detectThousandSeparator(Iterable<String> samples) {
    var dot = 0, comma = 0;
    for (final s in samples) {
      if (RegExp(r'\d\.\d{3}(\D|$)').hasMatch(s)) dot++;
      if (RegExp(r'\d,\d{3}(\D|$)').hasMatch(s)) comma++;
    }
    return comma > dot ? ',' : '.';
  }

  // ─── Values ──────────────────────────────────────────────────────────────

  /// Whole rupiah, sign kept ("−45.000", "(45.000)" → −45000). Null when
  /// not a valid number (e.g. "1.2.000").
  static int? parseAmount(String raw, String thousandSep) {
    var s = raw
        .trim()
        .replaceAll(RegExp(r'rp\.?|idr|\s', caseSensitive: false), '');
    if (s.isEmpty) return null;
    var negative = false;
    if (s.startsWith('(') && s.endsWith(')')) {
      negative = true;
      s = s.substring(1, s.length - 1);
    }
    if (s.startsWith('-') || s.startsWith('−')) {
      negative = true;
      s = s.substring(1);
    } else if (s.startsWith('+')) {
      s = s.substring(1);
    }
    final decimalSep = thousandSep == '.' ? ',' : '.';
    // Plain machine numbers ("45000", "12500.5") from Excel cells.
    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(s) &&
        !(thousandSep == '.' && RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(s))) {
      final v = double.parse(s).round();
      return negative ? -v : v;
    }
    final parts = s.split(decimalSep);
    if (parts.length > 2) return null;
    final whole = parts.first;
    final groups = whole.split(thousandSep);
    if (groups.isEmpty || groups.any((g) => !RegExp(r'^\d+$').hasMatch(g))) {
      return null;
    }
    if (groups.length > 1 &&
        (groups.first.length > 3 || groups.skip(1).any((g) => g.length != 3))) {
      return null;
    }
    var value = int.parse(groups.join());
    if (parts.length == 2) {
      if (!RegExp(r'^\d+$').hasMatch(parts[1])) return null;
      value = double.parse('$value.${parts[1]}').round();
    }
    return negative ? -value : value;
  }

  /// Strict date: 31/02/2025 → null. Also accepts ISO and Excel serials.
  static DateTime? parseDate(String raw, DateOrder order, [String? time]) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    DateTime? date;
    final serial = double.tryParse(s);
    if (serial != null && serial > 1 && serial < 100000 && !s.contains('/')) {
      date = DateTime(1899, 12, 30)
          .add(Duration(milliseconds: (serial * 86400000).round()));
    } else {
      final m = _dateParts.firstMatch(s);
      if (m == null) return null;
      final a = int.parse(m[1]!), b = int.parse(m[2]!), c = int.parse(m[3]!);
      final (y, mo, d) = m[1]!.length == 4
          ? (a, b, c)
          : switch (order) {
              DateOrder.dmy => (c, b, a),
              DateOrder.mdy => (c, a, b),
              DateOrder.ymd => (a, b, c),
            };
      final year = y < 100 ? 2000 + y : y;
      final candidate = DateTime(year, mo, d);
      if (candidate.year != year ||
          candidate.month != mo ||
          candidate.day != d) {
        return null;
      }
      date = candidate;
      final rest =
          RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(s.substring(m.end));
      if (rest != null) {
        date = DateTime(year, mo, d, int.parse(rest[1]!), int.parse(rest[2]!));
      }
    }
    final t = time == null
        ? null
        : RegExp(r'^(\d{1,2})[:.](\d{2})').firstMatch(time.trim());
    if (t != null) {
      final h = int.parse(t[1]!), mi = int.parse(t[2]!);
      if (h < 24 && mi < 60) {
        date = DateTime(date.year, date.month, date.day, h, mi);
      }
    }
    return date;
  }

  static String? parseType(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return null;
    if (const ['pengeluaran', 'keluar', 'expense', 'debit', 'out', 'belanja']
        .contains(s)) {
      return 'pengeluaran';
    }
    if (const ['pemasukan', 'masuk', 'income', 'kredit', 'credit', 'in']
        .contains(s)) {
      return 'pemasukan';
    }
    if (const ['transfer', 'pindah', 'pindah saldo'].contains(s)) {
      return 'transfer';
    }
    return '?';
  }

  /// Same date + type + amount + account + note = duplicate (SC-007).
  static String duplicateKey({
    required DateTime date,
    required String type,
    required int amount,
    required String account,
    required String note,
  }) =>
      '${date.year}-${date.month}-${date.day}|$type|${amount.abs()}|'
      '${account.trim().toLowerCase()}|'
      '${note.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ')}';

  /// Duplicate keys of existing DB rows (joined `accountName`).
  static Set<String> keysOf(Iterable<Map<String, dynamic>> rows) => {
        for (final t in rows)
          duplicateKey(
            date: DateTime.parse(t['date'] as String),
            type: t['type'] as String,
            amount: t['amount'] as int,
            account: t['accountName'] as String? ?? '',
            note: t['note'] as String? ?? '',
          ),
      };

  // ─── Preview ─────────────────────────────────────────────────────────────

  static ImportPreview buildPreview(
    ParsedFile file,
    Map<ImportField, int?> mapping, {
    required DateOrder order,
    required String thousandSep,
    required Set<String> existingKeys,
    required Set<String> existingCategories,
    required Set<String> existingAccounts,
    String? defaultAccount,
  }) {
    String cell(List<String> row, ImportField f) {
      final i = mapping[f];
      return i == null || i >= row.length ? '' : row[i].trim();
    }

    final ready = <ImportRow>[];
    final duplicates = <ImportRow>[];
    final problems = <ImportProblem>[];
    final newCats = <String, NewName>{};
    final newAccs = <String, NewName>{};

    for (var r = 0; r < file.rows.length; r++) {
      final raw = file.rows[r];
      final line = r + 2;
      void problem(String reason) =>
          problems.add(ImportProblem(line, reason, raw));

      final dateText = cell(raw, ImportField.date);
      final date = parseDate(dateText, order, cell(raw, ImportField.time));
      if (date == null) {
        problem(dateText.isEmpty
            ? 'Tanggal kosong'
            : 'Tanggal tidak valid: $dateText');
        continue;
      }
      final amountText = cell(raw, ImportField.amount);
      final signed = parseAmount(amountText, thousandSep);
      if (signed == null) {
        problem(amountText.isEmpty
            ? 'Jumlah kosong'
            : 'Jumlah tidak valid: $amountText');
        continue;
      }
      if (signed == 0) {
        problem('Jumlah 0');
        continue;
      }
      var type = parseType(cell(raw, ImportField.type)) ??
          (signed < 0 ? 'pengeluaran' : 'pemasukan');
      if (type == '?') {
        problem('Jenis tidak dikenal: ${cell(raw, ImportField.type)}');
        continue;
      }
      final account = cell(raw, ImportField.account).isNotEmpty
          ? cell(raw, ImportField.account)
          : defaultAccount;
      if (account == null || account.isEmpty) {
        problem('Rekening kosong');
        continue;
      }
      final destination = cell(raw, ImportField.destination);
      if (type == 'transfer') {
        if (destination.isEmpty) {
          problem('Transfer tanpa rekening tujuan');
          continue;
        }
        if (destination.toLowerCase() == account.toLowerCase()) {
          problem('Rekening asal dan tujuan sama');
          continue;
        }
      }
      final feeText = cell(raw, ImportField.fee);
      final fee = feeText.isEmpty ? 0 : parseAmount(feeText, thousandSep);
      if (fee == null || fee < 0) {
        problem('Biaya admin tidak valid: $feeText');
        continue;
      }
      final categoryText = cell(raw, ImportField.category);
      final category = type == 'transfer'
          ? null
          : (categoryText.isEmpty ? 'Lainnya' : categoryText);
      final note = cell(raw, ImportField.note);

      final row = ImportRow(
        line: line,
        date: date,
        type: type,
        amount: signed.abs(),
        category: category,
        account: account,
        destination: type == 'transfer' ? destination : null,
        note: note,
        fee: type == 'transfer' ? fee : 0,
      );
      final key = duplicateKey(
          date: date,
          type: type,
          amount: row.amount,
          account: account,
          note: note);
      if (existingKeys.contains(key)) {
        duplicates.add(row);
        continue;
      }
      ready.add(row);
      if (category != null &&
          !existingCategories.contains('$type|${category.toLowerCase()}')) {
        final n = NewName(category, type);
        newCats.putIfAbsent(n.key, () => n);
      }
      for (final a in [account, if (type == 'transfer') destination]) {
        if (!existingAccounts.contains(a.toLowerCase())) {
          final n = NewName(a);
          newAccs.putIfAbsent(n.key, () => n);
        }
      }
    }
    return ImportPreview(
      ready: ready,
      duplicates: duplicates,
      problems: problems,
      newCategories: newCats.values.toList(),
      newAccounts: newAccs.values.toList(),
    );
  }

  /// "Unduh daftar": problem rows as CSV with the reason in front.
  static String problemsCsv(ParsedFile file, List<ImportProblem> problems) =>
      encodeCsv([
        ['Baris', 'Alasan', ...file.headers],
        for (final p in problems) ['${p.line}', p.reason, ...p.raw],
      ]);
}
