import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Thrown for any decrypt / tag failure. Deliberately carries no detail
/// ("Kata sandi salah" is all the UI may say).
class WrongPassword implements Exception {
  const WrongPassword();
  @override
  String toString() => 'WrongPassword';
}

class InvalidBackup implements Exception {
  final String reason;
  const InvalidBackup(this.reason);
  @override
  String toString() => 'InvalidBackup: $reason';
}

/// Header of an `.artv` file (contracts/backup-file-format.md).
class BackupHeader {
  /// 1 for `.artv`; 0 for a legacy plain SQLite file.
  final int version;
  final DateTime createdAt;
  final String device;
  final int txCount;
  final int accountCount;
  final int dbVersion;
  final bool locked;
  final String? hint;
  final int iterations;
  final List<int>? salt;
  final List<int>? nonce;

  const BackupHeader({
    this.version = 1,
    required this.createdAt,
    required this.device,
    required this.txCount,
    required this.accountCount,
    required this.dbVersion,
    this.locked = false,
    this.hint,
    this.iterations = BackupCodec.defaultIterations,
    this.salt,
    this.nonce,
  });

  BackupHeader copyWith({List<int>? nonce}) => BackupHeader(
        version: version,
        createdAt: createdAt,
        device: device,
        txCount: txCount,
        accountCount: accountCount,
        dbVersion: dbVersion,
        locked: locked,
        hint: hint,
        iterations: iterations,
        salt: salt,
        nonce: nonce ?? this.nonce,
      );

  Map<String, dynamic> toJson() => {
        'v': version,
        'createdAt': createdAt.toIso8601String(),
        'device': device,
        'txCount': txCount,
        'accountCount': accountCount,
        'dbVersion': dbVersion,
        'locked': locked,
        if (hint != null && hint!.isNotEmpty) 'hint': hint,
        if (locked) ...{
          'kdf': {
            'alg': 'PBKDF2-HMAC-SHA256',
            'iter': iterations,
            'salt': base64Encode(salt!),
          },
          'cipher': {'alg': 'AES-256-GCM', 'nonce': base64Encode(nonce!)},
        },
      };

  factory BackupHeader.fromJson(Map<String, dynamic> j) {
    final locked = j['locked'] == true;
    final kdf = j['kdf'] as Map<String, dynamic>?;
    final cipher = j['cipher'] as Map<String, dynamic>?;
    if (locked && (kdf == null || cipher == null)) {
      throw const InvalidBackup('missing kdf/cipher');
    }
    return BackupHeader(
      version: (j['v'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      device: j['device'] as String? ?? '—',
      txCount: (j['txCount'] as num?)?.toInt() ?? 0,
      accountCount: (j['accountCount'] as num?)?.toInt() ?? 0,
      dbVersion: (j['dbVersion'] as num?)?.toInt() ?? 0,
      locked: locked,
      hint: j['hint'] as String?,
      iterations:
          (kdf?['iter'] as num?)?.toInt() ?? BackupCodec.defaultIterations,
      salt: kdf == null ? null : base64Decode(kdf['salt'] as String),
      nonce: cipher == null ? null : base64Decode(cipher['nonce'] as String),
    );
  }
}

/// A decoded backup: header plus the SQLite file bytes.
class DecodedBackup {
  final BackupHeader header;
  final Uint8List database;
  const DecodedBackup(this.header, this.database);
}

/// Pure encoder/decoder for `.artv` v1:
/// `"ARTV1" | uint32 BE header length | header JSON | payload`.
/// Locked payload = AES-256-GCM(ciphertext ‖ 16-byte tag), key from
/// PBKDF2-HMAC-SHA256.
abstract final class BackupCodec {
  static const magic = 'ARTV1';
  static const defaultIterations = 210000;
  static final _sqliteMagic = utf8.encode('SQLite format 3\u0000');
  static final _aes = AesGcm.with256bits();

  static List<int> randomBytes(int n) {
    final r = Random.secure();
    return List<int>.generate(n, (_) => r.nextInt(256));
  }

  static List<int> newSalt() => randomBytes(16);

  /// Raw 32-byte key; callers may cache it to back up without asking again.
  static Future<List<int>> deriveKey(String password, List<int> salt,
      {int iterations = defaultIterations}) async {
    final kdf = Pbkdf2.hmacSha256(iterations: iterations, bits: 256);
    final key =
        await kdf.deriveKeyFromPassword(password: password, nonce: salt);
    return key.extractBytes();
  }

  /// Builds a file. When [header.locked], [key] (32 bytes from [deriveKey]
  /// with `header.salt`) is required; a fresh nonce is generated.
  static Future<Uint8List> encode(Uint8List database, BackupHeader header,
      {List<int>? key}) async {
    var h = header;
    List<int> payload = database;
    if (header.locked) {
      if (key == null || header.salt == null) {
        throw ArgumentError('locked backup needs key and salt');
      }
      h = header.copyWith(nonce: randomBytes(12));
      final box = await _aes.encrypt(database,
          secretKey: SecretKey(key), nonce: h.nonce!);
      payload = [...box.cipherText, ...box.mac.bytes];
    }
    final json = utf8.encode(jsonEncode(h.toJson()));
    final out = BytesBuilder(copy: false)
      ..add(utf8.encode(magic))
      ..add((ByteData(4)..setUint32(0, json.length)).buffer.asUint8List())
      ..add(json)
      ..add(payload);
    return out.toBytes();
  }

  static bool isLegacy(Uint8List bytes) =>
      bytes.length >= _sqliteMagic.length && _startsWith(bytes, _sqliteMagic);

  static bool _startsWith(List<int> bytes, List<int> prefix) {
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix[i]) return false;
    }
    return true;
  }

  /// Header only (no decryption) — for "Cadangan ditemukan".
  static BackupHeader readHeader(Uint8List bytes) => _split(bytes).$1;

  static (BackupHeader, Uint8List) _split(Uint8List bytes) {
    if (isLegacy(bytes)) {
      return (
        BackupHeader(
          version: 0,
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          device: '—',
          txCount: 0,
          accountCount: 0,
          dbVersion: 0,
        ),
        bytes
      );
    }
    final m = utf8.encode(magic);
    if (bytes.length < 9 || !_startsWith(bytes, m)) {
      throw const InvalidBackup('bad magic');
    }
    final len = ByteData.sublistView(bytes, 5, 9).getUint32(0);
    if (9 + len > bytes.length) throw const InvalidBackup('truncated');
    final json = jsonDecode(utf8.decode(bytes.sublist(9, 9 + len)));
    return (
      BackupHeader.fromJson(json as Map<String, dynamic>),
      Uint8List.sublistView(bytes, 9 + len)
    );
  }

  /// Returns the SQLite bytes. Locked files need [password] or a cached
  /// [key]; any failure throws [WrongPassword].
  static Future<DecodedBackup> decode(Uint8List bytes,
      {String? password, List<int>? key}) async {
    final (header, payload) = _split(bytes);
    if (!header.locked) return DecodedBackup(header, payload);
    if (payload.length < 16) throw const WrongPassword();
    try {
      final k = key ??
          (password == null
              ? throw const WrongPassword()
              : await deriveKey(password, header.salt!,
                  iterations: header.iterations));
      final cut = payload.length - 16;
      final clear = await _aes.decrypt(
        SecretBox(payload.sublist(0, cut),
            nonce: header.nonce!, mac: Mac(payload.sublist(cut))),
        secretKey: SecretKey(k),
      );
      return DecodedBackup(header, Uint8List.fromList(clear));
    } catch (_) {
      throw const WrongPassword();
    }
  }
}
