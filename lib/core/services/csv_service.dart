import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/database/transaction_store.dart';
import 'package:artavia/widgets/commons/common.dart';

/// Column order of contracts/csv-format.md.
const csvHeader = [
  'date',
  'type',
  'amount',
  'category',
  'account',
  'destination_account',
  'admin_fee',
  'note',
];
const _validTypes = {'pengeluaran', 'pemasukan', 'transfer'};

// ─── Pure CSV (RFC 4180 subset) ───────────────────────────────────────────────

String _escape(String value) {
  final needsQuotes = value.contains(RegExp(r'[",\r\n]'));
  final escaped = value.replaceAll('"', '""');
  return needsQuotes ? '"$escaped"' : escaped;
}

String encodeCsv(List<List<String>> rows) =>
    rows.map((r) => r.map(_escape).join(',')).join('\r\n');

/// Parses CSV text into rows; handles quoted commas, quotes and newlines.
List<List<String>> decodeCsv(String text) {
  final input = text.startsWith('\uFEFF') ? text.substring(1) : text;
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < input.length; i++) {
    final c = input[i];
    if (inQuotes) {
      if (c != '"') {
        field.write(c);
      } else if (i + 1 < input.length && input[i + 1] == '"') {
        field.write('"');
        i++;
      } else {
        inQuotes = false;
      }
    } else if (c == '"') {
      inQuotes = true;
    } else if (c == ',') {
      row.add(field.toString());
      field.clear();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < input.length && input[i + 1] == '\n') i++;
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = <String>[];
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows.where((r) => !(r.length == 1 && r.first.trim().isEmpty)).toList();
}

/// Converts a DB transaction row (with joined names) to CSV fields.
List<String> transactionToCsv(Map<String, dynamic> t) {
  final isTransfer = t['type'] == 'transfer';
  return [
    DateTime.parse(t['date'] as String).toIso8601String().split('.').first,
    t['type'] as String,
    '${t['amount']}',
    isTransfer ? '' : (t['categoryName'] as String? ?? 'Lainnya'),
    t['accountName'] as String? ?? '',
    isTransfer ? (t['destinationAccountName'] as String? ?? '') : '',
    isTransfer ? '${t['admin_fee'] ?? 0}' : '0',
    t['note'] as String? ?? '',
  ];
}

class CsvImportResult {
  final List<Map<String, dynamic>> valid;
  final List<String> errors;

  const CsvImportResult(this.valid, this.errors);
}

/// Validates parsed rows against the contract. Line numbers are 1-based.
CsvImportResult validateCsv(List<List<String>> rows) {
  if (rows.isEmpty ||
      rows.first.map((h) => h.trim().toLowerCase()).join(',') !=
          csvHeader.join(',')) {
    return const CsvImportResult([], ['Header tidak sesuai format Artavia']);
  }
  final valid = <Map<String, dynamic>>[];
  final errors = <String>[];
  for (var i = 1; i < rows.length; i++) {
    final error = _rowError(rows[i]);
    if (error != null) {
      errors.add('Baris ${i + 1}: $error');
    } else {
      valid.add(_rowToMap(rows[i]));
    }
  }
  return CsvImportResult(valid, errors);
}

String? _rowError(List<String> r) {
  if (r.length != csvHeader.length) return 'jumlah kolom salah';
  if (DateTime.tryParse(r[0].trim()) == null) return 'tanggal tidak valid';
  final type = r[1].trim();
  if (!_validTypes.contains(type)) return 'jenis tidak dikenal';
  final amount = int.tryParse(r[2].trim());
  if (amount == null || amount <= 0) return 'nominal tidak valid';
  if (r[4].trim().isEmpty) return 'rekening kosong';
  if (type != 'transfer') {
    return r[3].trim().isEmpty ? 'kategori kosong' : null;
  }
  final dest = r[5].trim();
  if (dest.isEmpty) return 'rekening tujuan kosong';
  if (dest.toLowerCase() == r[4].trim().toLowerCase()) {
    return 'rekening asal dan tujuan sama';
  }
  final fee = int.tryParse(r[6].trim().isEmpty ? '0' : r[6].trim());
  return fee == null || fee < 0 ? 'biaya admin tidak valid' : null;
}

Map<String, dynamic> _rowToMap(List<String> r) => {
      'date': DateTime.parse(r[0].trim()).toIso8601String(),
      'type': r[1].trim(),
      'amount': int.parse(r[2].trim()),
      'category': r[3].trim(),
      'account': r[4].trim(),
      'destination_account': r[5].trim(),
      'admin_fee': int.tryParse(r[6].trim()) ?? 0,
      'note': r[7],
    };

// ─── File I/O (FR-031e / FR-031f) ─────────────────────────────────────────────

class CsvService {
  CsvService._();

  /// Writes all transactions to a CSV file and opens the share sheet.
  /// Returns the number of exported rows.
  static Future<int> exportAndShare() async {
    final data = await DatabaseHelper.instance.readAllTransactions();
    final csv = encodeCsv([csvHeader, ...data.map(transactionToCsv)]);
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .split('.')
        .first
        .replaceAll(RegExp(r'[-:]'), '')
        .replaceAll('T', '-');
    final file = File('${dir.path}/artavia-$stamp.csv');
    // BOM so spreadsheet apps detect UTF-8.
    await file.writeAsString('\uFEFF$csv\r\n');
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Ekspor transaksi Artavia',
    ));
    return data.length;
  }

  /// Lets the user choose a CSV and validates it. `null` when cancelled.
  static Future<CsvImportResult?> pickAndValidate() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (files.isEmpty) return null;
    final text = await files.first.xFile.readAsString();
    return validateCsv(decodeCsv(text));
  }

  static Future<int> import(List<Map<String, dynamic>> rows) =>
      DatabaseHelper.instance.importTransactions(
        rows,
        newCategoryColor: (i) => paletteColorAt(i).toARGB32(),
      );
}
