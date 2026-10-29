import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:artavia/core/services/backup_codec.dart';

// Fewer iterations keep the test fast; the header records the count used.
const _iter = 1000;

Uint8List _fakeDb() => Uint8List.fromList([
      ...utf8.encode('SQLite format 3\u0000'),
      ...List.generate(500, (i) => i % 251)
    ]);

BackupHeader _header({bool locked = false, List<int>? salt}) => BackupHeader(
      createdAt: DateTime(2026, 10, 27, 8),
      device: 'Android',
      txCount: 1248,
      accountCount: 7,
      dbVersion: 12,
      locked: locked,
      hint: locked ? 'nama kucing pertama' : null,
      iterations: _iter,
      salt: salt,
    );

void main() {
  test('unlocked round-trip keeps bytes and header', () async {
    final file = await BackupCodec.encode(_fakeDb(), _header());
    expect(utf8.decode(file.sublist(0, 5)), 'ARTV1');
    final out = await BackupCodec.decode(file);
    expect(out.database, _fakeDb());
    expect(out.header.txCount, 1248);
    expect(out.header.locked, isFalse);
  });

  test('locked round-trip with password and with cached key', () async {
    final salt = BackupCodec.newSalt();
    final key =
        await BackupCodec.deriveKey('rahasia123', salt, iterations: _iter);
    final file = await BackupCodec.encode(
        _fakeDb(), _header(locked: true, salt: salt),
        key: key);

    // Payload is not the plain database.
    expect(file.length, greaterThan(_fakeDb().length));
    final header = BackupCodec.readHeader(file);
    expect(header.locked, isTrue);
    expect(header.hint, 'nama kucing pertama');
    expect(header.iterations, _iter);

    expect((await BackupCodec.decode(file, password: 'rahasia123')).database,
        _fakeDb());
    expect((await BackupCodec.decode(file, key: key)).database, _fakeDb());
  });

  test('wrong or missing password → WrongPassword', () async {
    final salt = BackupCodec.newSalt();
    final key = await BackupCodec.deriveKey('benar', salt, iterations: _iter);
    final file = await BackupCodec.encode(
        _fakeDb(), _header(locked: true, salt: salt),
        key: key);
    expect(() => BackupCodec.decode(file, password: 'salah'),
        throwsA(isA<WrongPassword>()));
    expect(() => BackupCodec.decode(file), throwsA(isA<WrongPassword>()));
  });

  test('tampered ciphertext or tag → WrongPassword (uniform)', () async {
    final salt = BackupCodec.newSalt();
    final key = await BackupCodec.deriveKey('benar', salt, iterations: _iter);
    final file = await BackupCodec.encode(
        _fakeDb(), _header(locked: true, salt: salt),
        key: key);
    final flipped = Uint8List.fromList(file)..[file.length - 1] ^= 0x01;
    expect(() => BackupCodec.decode(flipped, key: key),
        throwsA(isA<WrongPassword>()));
    final body = Uint8List.fromList(file)..[file.length - 40] ^= 0x01;
    expect(() => BackupCodec.decode(body, key: key),
        throwsA(isA<WrongPassword>()));
  });

  test('legacy plain artavia_backup.db is accepted as v0 unlocked', () async {
    final out = await BackupCodec.decode(_fakeDb());
    expect(out.header.version, 0);
    expect(out.header.locked, isFalse);
    expect(out.database, _fakeDb());
  });

  test('garbage is rejected', () {
    expect(() => BackupCodec.readHeader(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<InvalidBackup>()));
  });
}
