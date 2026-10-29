import 'package:flutter_test/flutter_test.dart';
import 'package:artavia/core/utils/transfer_math.dart';

void main() {
  test('Pengirim: source −(amount + fee), destination +amount', () {
    final p = TransferMath.preview(
        amount: 100000,
        fee: 2500,
        bearer: FeeBearer.sender,
        sourceBalance: 1000000);
    expect(p.sourceDelta, -102500);
    expect(p.destDelta, 100000);
    expect(p.fee, 2500);
    expect(p.shortfall, 0);
    expect(p.isValid, isTrue);
  });

  test('Penerima: source −amount, destination +(amount − fee)', () {
    final p = TransferMath.preview(
        amount: 100000,
        fee: 4000,
        bearer: FeeBearer.receiver,
        sourceBalance: 1000000);
    expect(p.sourceDelta, -100000);
    expect(p.destDelta, 96000);
    expect(p.isValid, isTrue);
  });

  test('Penerima with fee ≥ amount is invalid', () {
    final p = TransferMath.preview(
        amount: 4000,
        fee: 4000,
        bearer: FeeBearer.receiver,
        sourceBalance: 1000000);
    expect(p.isValid, isFalse);
    expect(p.error, TransferMath.feeTooHigh);
  });

  test('shortfall is a warning: 600.000 + 2.500 on 20.000 → 582.500', () {
    final p = TransferMath.preview(
        amount: 600000,
        fee: 2500,
        bearer: FeeBearer.sender,
        sourceBalance: 20000);
    expect(p.shortfall, 582500);
    expect(p.isValid, isTrue);
  });

  test('zero amount is not savable but has no error text', () {
    final p = TransferMath.preview(
        amount: 0, fee: 0, bearer: FeeBearer.sender, sourceBalance: 0);
    expect(p.isValid, isFalse);
    expect(p.error, isNull);
  });

  test('quick chips: remembered first, common fees deduped', () {
    expect(TransferFeeMemory.quickChips(null), [2500, 6500]);
    expect(TransferFeeMemory.quickChips(const FeePref(2500, FeeBearer.sender)),
        [2500, 6500]);
    expect(TransferFeeMemory.quickChips(const FeePref(4000, FeeBearer.sender)),
        [4000, 2500, 6500]);
    expect(TransferFeeMemory.quickChips(const FeePref(0, FeeBearer.sender)),
        [2500, 6500]);
  });

  test('memory round-trips per ordered pair', () async {
    final store = <String, String>{};
    final mem =
        TransferFeeMemory((k) => store[k], (k, v) async => store[k] = v);
    await mem.write(1, 2, const FeePref(2500, FeeBearer.receiver));
    expect(store.keys, ['transfer_fee:1:2']);
    expect(mem.read(1, 2), const FeePref(2500, FeeBearer.receiver));
    expect(mem.read(2, 1), isNull);
    expect(FeePref.fromJson('broken'), isNull);
  });
}
