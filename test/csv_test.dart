import 'package:flutter_test/flutter_test.dart';
import 'package:artavia/core/services/csv_service.dart';

void main() {
  test('encode/decode round-trips quotes, commas and newlines', () {
    final rows = [
      csvHeader,
      [
        '2026-10-25T08:00:00',
        'pengeluaran',
        '15000',
        'Makanan',
        'Dompet',
        '',
        '0',
        'Kopi, roti "enak"\nbaris dua'
      ],
    ];
    final decoded = decodeCsv('\uFEFF${encodeCsv(rows)}\r\n');
    expect(decoded, rows);
  });

  test('validateCsv accepts valid rows and reports invalid ones', () {
    final text = [
      csvHeader.join(','),
      '2026-10-25T08:00:00,pengeluaran,15000,Makanan,Dompet,,0,Kopi',
      '2026-10-25,transfer,50000,,Dompet,BCA,2500,Isi saldo',
      '2026-10-25,pengeluaran,-5,Makanan,Dompet,,0,',
      '2026-10-25,transfer,100,,Dompet,dompet,0,',
      'bukan-tanggal,pemasukan,10,Gaji,BCA,,0,',
    ].join('\n');
    final result = validateCsv(decodeCsv(text));
    expect(result.valid, hasLength(2));
    expect(result.valid[1]['admin_fee'], 2500);
    expect(result.errors, hasLength(3));
    expect(result.errors.first, startsWith('Baris 4'));
  });

  test('wrong header is rejected', () {
    final result = validateCsv(decodeCsv('a,b,c\n1,2,3'));
    expect(result.valid, isEmpty);
    expect(result.errors.single, contains('Header'));
  });

  test('transactionToCsv uses joined names and transfer fields', () {
    final row = transactionToCsv({
      'date': '2026-10-25T08:00:00.000',
      'type': 'transfer',
      'amount': 50000,
      'accountName': 'Dompet',
      'destinationAccountName': 'BCA',
      'admin_fee': 2500,
      'note': 'x',
    });
    expect(row, [
      '2026-10-25T08:00:00',
      'transfer',
      '50000',
      '',
      'Dompet',
      'BCA',
      '2500',
      'x'
    ]);
  });
}
