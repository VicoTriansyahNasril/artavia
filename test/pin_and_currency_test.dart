import 'package:flutter_test/flutter_test.dart';
import 'package:artavia/core/services/pin_lock_service.dart';
import 'package:artavia/core/utils/currency_format.dart';

void main() {
  test('PIN hash is salted and verifiable', () async {
    final salt = newPinSalt();
    final a = await hashPin('1234', salt);
    final b = await hashPin('1234', salt);
    final other = await hashPin('1234', newPinSalt());
    expect(salt, hasLength(16));
    expect(hashesEqual(a, b), isTrue);
    expect(hashesEqual(a, other), isFalse);
    expect(hashesEqual(a, await hashPin('4321', salt)), isFalse);
  });

  test('number format follows the separator setting', () {
    final money = CurrencyService.to;
    money.useCommaSeparator = false;
    expect(money.formatWithoutSymbol(1250000), '1.250.000');
    money.useCommaSeparator = true;
    expect(money.formatWithoutSymbol(1250000), '1,250,000');
    expect(money.groupSeparator, ',');
    money.useCommaSeparator = false;
  });
}
