import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:artavia/core/services/import_service.dart';

ParsedFile _csv(String text) => ImportService.parseImportFile(
    'data.csv', Uint8List.fromList(utf8.encode(text)));

ImportPreview _preview(ParsedFile f,
        {Set<String> keys = const {},
        Set<String> cats = const {'pengeluaran|makanan'},
        Set<String> accs = const {'bca'}}) =>
    ImportService.buildPreview(
      f,
      ImportService.guessMapping(f.headers),
      order: ImportService.detectDateOrder(f.rows.map((r) => r.first)),
      thousandSep: ImportService.detectThousandSeparator(
          f.rows.map((r) => r.length > 1 ? r[1] : '')),
      existingKeys: keys,
      existingCategories: cats,
      existingAccounts: accs,
      defaultAccount: 'BCA',
    );

void main() {
  test('header synonyms map; "Rekening tujuan" does not steal Rekening', () {
    final m = ImportService.guessMapping(ImportService.exportHeaders);
    expect(m[ImportField.account], 5);
    expect(m[ImportField.destination], 6);
    expect(m[ImportField.fee], 7);
    final m2 = ImportService.guessMapping(['Tgl', 'Nominal', 'Keterangan']);
    expect(m2[ImportField.date], 0);
    expect(m2[ImportField.amount], 1);
    expect(m2[ImportField.note], 2);
    expect(ImportService.missingRequired({ImportField.date: 0}), ['Jumlah']);
  });

  test('31/02 and empty amount are problems with reasons', () {
    final p = _preview(_csv('Tanggal,Jumlah,Catatan\n'
        '31/02/2025,10.000,x\n'
        '01/02/2025,,y\n'
        '01/02/2025,15.000,z\n'));
    expect(p.problems.map((e) => e.reason),
        ['Tanggal tidak valid: 31/02/2025', 'Jumlah kosong']);
    expect(p.problems.map((e) => e.line), [2, 3]);
    expect(p.ready.single.amount, 15000);
  });

  test('"1.2.000" is not a valid amount', () {
    expect(ImportService.parseAmount('1.2.000', '.'), isNull);
    expect(ImportService.parseAmount('Rp 1.250.000', '.'), 1250000);
    expect(ImportService.parseAmount('1,250,000', ','), 1250000);
    expect(ImportService.parseAmount('(45.000)', '.'), -45000);
    expect(ImportService.parseAmount('−45.000', '.'), -45000);
    expect(ImportService.parseAmount('12500.5', '.'), 12501);
    expect(ImportService.parseAmount('45000', '.'), 45000);
  });

  test('sign decides the type when there is no Jenis column', () {
    final p = _preview(
        _csv('Tanggal,Jumlah\n01/10/2026,-45.000\n02/10/2026,8.500.000\n'));
    expect(p.ready.map((r) => r.type), ['pengeluaran', 'pemasukan']);
    expect(p.ready.map((r) => r.amount), [45000, 8500000]);
  });

  test('duplicates against existing data are counted and skipped', () {
    final key = ImportService.duplicateKey(
        date: DateTime(2026, 10, 1),
        type: 'pengeluaran',
        amount: 45000,
        account: 'BCA',
        note: 'Makan  siang');
    final p = _preview(
        _csv('Tanggal,Jumlah,Jenis,Rekening,Catatan\n'
            '01/10/2026,45.000,Pengeluaran,bca,makan siang\n'
            '01/10/2026,46.000,Pengeluaran,bca,makan siang\n'),
        keys: {key});
    expect(p.duplicates.length, 1);
    expect(p.ready.length, 1);
  });

  test('new categories and accounts are reported once', () {
    final p = _preview(_csv('Tanggal,Jumlah,Kategori,Rekening\n'
        '01/10/2026,-5.000,Kopi,GoPay\n'
        '02/10/2026,-6.000,kopi,GoPay\n'
        '03/10/2026,-7.000,Makanan,BCA\n'));
    expect(p.newCategories.map((n) => n.name), ['Kopi']);
    expect(p.newAccounts.map((n) => n.name), ['GoPay']);
  });

  test('date order and Excel serial dates', () {
    expect(ImportService.detectDateOrder(['12/31/2026', '01/02/2026']),
        DateOrder.mdy);
    expect(ImportService.detectDateOrder(['2026-10-01']), DateOrder.ymd);
    expect(
        ImportService.parseDate('46296', DateOrder.dmy), DateTime(2026, 10, 1));
    expect(ImportService.parseDate('01/10/2026', DateOrder.dmy, '08:30'),
        DateTime(2026, 10, 1, 8, 30));
  });

  test('transfer needs a different destination', () {
    final p = _preview(_csv('Tanggal,Jumlah,Jenis,Rekening,Rekening tujuan\n'
        '01/10/2026,100.000,Transfer,BCA,\n'
        '01/10/2026,100.000,Transfer,BCA,bca\n'
        '01/10/2026,100.000,Transfer,BCA,GoPay\n'));
    expect(p.problems.map((e) => e.reason), [
      'Transfer tanpa rekening tujuan',
      'Rekening asal dan tujuan sama',
    ]);
    expect(p.ready.single.destination, 'GoPay');
  });

  test('unsupported file and empty file are rejected', () {
    expect(() => ImportService.parseImportFile('a.pdf', Uint8List(3)),
        throwsA(isA<ImportFileError>()));
    expect(() => _csv('Tanggal,Jumlah\n'), throwsA(isA<ImportFileError>()));
  });
}
