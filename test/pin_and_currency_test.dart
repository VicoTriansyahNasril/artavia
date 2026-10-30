import 'package:flutter/services.dart';
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

  group('CurrencyInputFormatter', () {
    final f = CurrencyInputFormatter();
    TextEditingValue type(String old, String text, int cursor) =>
        f.formatEditUpdate(
          TextEditingValue(text: old),
          TextEditingValue(
              text: text, selection: TextSelection.collapsed(offset: cursor)),
        );

    test('groups thousands while typing', () {
      final v = type('125.000', '125.0000', 8);
      expect(v.text, '1.250.000');
      expect(v.selection.baseOffset, 9);
      expect(CurrencyInputFormatter.parse(v.text), 1250000);
    });

    test('keeps the cursor beside the same digit on mid-edit', () {
      // "1.000" → insert "5" after the "1": "15.000" → "15.000", cursor after 5.
      final v = type('1.000', '15.000', 2);
      expect(v.text, '15.000');
      expect(v.selection.baseOffset, 2);
    });

    test('backspace over a separator deletes the digit before it', () {
      // "12.000" with cursor after "." → backspace removes the "2".
      final v = type('12.000', '12000', 2);
      expect(v.text, '1.000');
      expect(v.selection.baseOffset, 1);
      // Removing the lead digit keeps a single zero instead of "000".
      expect(type('1.000', '.000', 0).text, '0');
    });

    test('rejects non-digits, leading zeros and overflow', () {
      expect(type('', 'a1b2', 4).text, '12');
      expect(type('', '007', 3).text, '7');
      expect(type('', '0', 1).text, '0');
      expect(type('0', '', 0).text, '');
      expect(type('999.999.999.999', '9999.999.999.999', 1).text,
          '999.999.999.999');
    });

    test('follows the comma setting', () {
      CurrencyService.to.useCommaSeparator = true;
      expect(type('', '1250000', 7).text, '1,250,000');
      expect(CurrencyInputFormatter.initial(-50000), '50,000');
      CurrencyService.to.useCommaSeparator = false;
      expect(CurrencyInputFormatter.initial(0), '');
    });
  });
}
