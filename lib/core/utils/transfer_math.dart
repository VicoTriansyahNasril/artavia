import 'dart:convert';

/// Who absorbs the admin fee (board "Dipotong dari").
enum FeeBearer {
  /// Saldo asal: the source pays amount + fee.
  sender('Pengirim'),

  /// Uang diterima: the destination receives amount − fee.
  receiver('Penerima');

  final String dbValue;
  const FeeBearer(this.dbValue);

  static FeeBearer fromDb(String? v) =>
      v == receiver.dbValue ? receiver : sender;
}

/// Last fee used for one source→destination pair (FR-011).
class FeePref {
  final int fee;
  final FeeBearer bearer;
  const FeePref(this.fee, this.bearer);

  String toJson() => jsonEncode({'fee': fee, 'bearer': bearer.dbValue});

  static FeePref? fromJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return FeePref(
          (m['fee'] as num).toInt(), FeeBearer.fromDb(m['bearer'] as String?));
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is FeePref && other.fee == fee && other.bearer == bearer;

  @override
  int get hashCode => Object.hash(fee, bearer);
}

/// Live result of a transfer form (FR-012/FR-013).
class TransferPreview {
  /// Change to the source balance (≤ 0).
  final int sourceDelta;

  /// Change to the destination balance (≥ 0) — also the stored transfer amount.
  final int destDelta;

  /// Recorded as a separate "Biaya admin" expense from the source.
  final int fee;

  /// How far the source would go below zero (warning only, never blocks).
  final int shortfall;

  /// Blocking problem, e.g. fee ≥ amount when the receiver pays.
  final String? error;

  const TransferPreview({
    required this.sourceDelta,
    required this.destDelta,
    required this.fee,
    required this.shortfall,
    this.error,
  });

  bool get isValid => error == null && destDelta > 0;
}

abstract final class TransferMath {
  static const feeTooHigh = 'Biaya harus lebih kecil dari jumlah transfer';

  static TransferPreview preview({
    required int amount,
    required int fee,
    required FeeBearer bearer,
    required int sourceBalance,
  }) {
    final f = fee < 0 ? 0 : fee;
    if (amount <= 0) {
      return TransferPreview(
          sourceDelta: 0, destDelta: 0, fee: f, shortfall: 0);
    }
    if (bearer == FeeBearer.receiver && f >= amount) {
      return TransferPreview(
          sourceDelta: -amount,
          destDelta: 0,
          fee: f,
          shortfall: 0,
          error: feeTooHigh);
    }
    final out = bearer == FeeBearer.sender ? amount + f : amount;
    final received = bearer == FeeBearer.sender ? amount : amount - f;
    final shortfall = out - sourceBalance;
    return TransferPreview(
      sourceDelta: -out,
      destDelta: received,
      fee: f,
      shortfall: shortfall > 0 ? shortfall : 0,
    );
  }
}

/// Fee memory stored in settings under `transfer_fee:<from>:<to>`.
/// Storage is injected so the logic stays testable without a database.
class TransferFeeMemory {
  final String? Function(String key) _read;
  final Future<void> Function(String key, String value) _write;

  const TransferFeeMemory(this._read, this._write);

  static const commonFees = [2500, 6500];

  static String key(int fromId, int toId) => 'transfer_fee:$fromId:$toId';

  FeePref? read(int fromId, int toId) =>
      FeePref.fromJson(_read(key(fromId, toId)));

  Future<void> write(int fromId, int toId, FeePref pref) =>
      _write(key(fromId, toId), pref.toJson());

  /// Chips after "Tidak ada": the remembered fee first (history icon), then
  /// the common fees ascending, without duplicates.
  static List<int> quickChips(FeePref? last) {
    final remembered = last != null && last.fee > 0 ? last.fee : null;
    return [
      if (remembered != null) remembered,
      for (final f in commonFees)
        if (f != remembered) f,
    ];
  }
}
