import 'package:flutter_test/flutter_test.dart';
import 'package:artavia/core/utils/calc_engine.dart';

CalcEngine _type(String keys) {
  final c = CalcEngine();
  for (final k in keys.split(' ')) {
    c.press(k);
  }
  return c;
}

void main() {
  test('45.000 + 12.500 = 57.500 with expression', () {
    final c = _type('4 5 000 + 1 2 5 0 0');
    expect(c.result, 57500);
    expect(c.expression(), '45.000 + 12.500');
    expect(c.isValid, isTrue);
  });

  test('45.000 − 50.000 is invalid (≤ 0)', () {
    final c = _type('4 5 000 - 5 0 000');
    expect(c.result, -5000);
    expect(c.isValid, isFalse);
    expect(c.expression(), '45.000 − 50.000');
  });

  test('100 ÷ 3 = 33 and 5 ÷ 2 rounds half-up to 3', () {
    expect(_type('1 0 0 / 3').result, 33);
    expect(_type('5 / 2').result, 3);
    expect(_type('5 / 0').result, 0);
  });

  test('× and ÷ bind before + and −', () {
    expect(_type('2 + 3 * 4').result, 14);
    expect(_type('1 0 - 6 / 2').result, 7);
  });

  test('trailing operator is ignored; repeated operator replaces', () {
    expect(_type('1 2 +').result, 12);
    final c = _type('1 2 + -');
    expect(c.expression(), '12 −');
    expect(c.result, 12);
  });

  test('C clears, back removes a digit then the operator', () {
    final c = _type('1 2 + 3');
    c.press('back');
    expect(c.expression(), '12 +');
    c.press('back');
    expect(c.hasOperator, isFalse);
    expect(c.result, 12);
    c.press('C');
    expect(c.result, 0);
    expect(c.isEmpty, isTrue);
  });

  test('000 needs a non-zero number; leading zeros collapse', () {
    expect(_type('000').result, 0);
    expect(_type('0 5').result, 5);
    expect(_type('7 000').result, 7000);
  });

  test('more than 12 digits is rejected', () {
    final c = CalcEngine(999999999999);
    expect(c.press('1'), isFalse);
    expect(c.result, 999999999999);
  });

  test('group formats with the chosen separator', () {
    expect(CalcEngine.group(3284500), '3.284.500');
    expect(CalcEngine.group(3284500, ','), '3,284,500');
    expect(CalcEngine.group(-5000), '−5.000');
  });
}
