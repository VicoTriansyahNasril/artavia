import 'package:flutter_test/flutter_test.dart';
import 'package:artavia/core/utils/csv_codec.dart';
import 'package:artavia/core/utils/xlsx_codec.dart';

void main() {
  test('csv round-trips quotes, delimiters and newlines', () {
    final rows = [
      ['Tanggal', 'Jumlah', 'Catatan'],
      ['25/10/2026', '15000', 'Kopi, roti "enak"\nbaris dua'],
    ];
    expect(decodeCsv('﻿${encodeCsv(rows)}\r\n'), rows);
  });

  test('csv with ; (Excel Indonesia) is detected', () {
    expect(decodeCsv('Tanggal;Jumlah\n01/10/2026;1.500\n'), [
      ['Tanggal', 'Jumlah'],
      ['01/10/2026', '1.500'],
    ]);
  });

  test('xlsx round-trip: several sheets, numbers, text, escaping', () {
    final bytes = XlsxCodec.encode({
      'Transaksi': [
        ['Tanggal', 'Jumlah', 'Catatan'],
        ['01/10/2026', 45000, 'Makan & minum <kantor>'],
        ['02/10/2026', 12500.5, null],
      ],
      'Rekening': [
        ['Nama', 'Saldo'],
        ['BCA', -1750000],
      ],
    });
    final sheets = XlsxCodec.decode(bytes);
    expect(sheets.keys, ['Transaksi', 'Rekening']);
    expect(sheets['Transaksi']![1],
        ['01/10/2026', '45000', 'Makan & minum <kantor>']);
    expect(sheets['Transaksi']![2], ['02/10/2026', '12500.5']);
    expect(sheets['Rekening']![1], ['BCA', '-1750000']);
  });

  test('column names', () {
    expect(XlsxCodec.columnName(0), 'A');
    expect(XlsxCodec.columnName(25), 'Z');
    expect(XlsxCodec.columnName(26), 'AA');
    expect(XlsxCodec.columnIndex('AB12'), 27);
  });
}
