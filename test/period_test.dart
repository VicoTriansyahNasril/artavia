import 'package:flutter_test/flutter_test.dart';
import 'package:artavia/core/services/period_service.dart';

void main() {
  test('start day 1 is the calendar month', () {
    final p = Period.of(2026, 10, 1);
    expect(p.start, DateTime(2026, 10, 1));
    expect(p.end, DateTime(2026, 11, 1));
    expect(p.label, 'Okt 2026');
  });

  test('start day 25: "Okt" covers 25 Sep – 24 Okt', () {
    final p = Period.of(2026, 10, 25);
    expect(p.start, DateTime(2026, 9, 25));
    expect(p.end, DateTime(2026, 10, 25));
  });

  test('month overflow is normalized (Des + 1 = Jan next year)', () {
    final p = Period.of(2026, 13, 1);
    expect(p.year, 2027);
    expect(p.month, 1);
    final q = Period.of(2027, 1, 25);
    expect(q.start, DateTime(2026, 12, 25));
  });

  test('containing picks the period a date falls in', () {
    expect(Period.containing(DateTime(2026, 9, 26), 25).month, 10);
    expect(Period.containing(DateTime(2026, 10, 24), 25).month, 10);
    expect(Period.containing(DateTime(2026, 12, 30), 25).year, 2027);
    expect(Period.containing(DateTime(2026, 10, 31), 1).month, 10);
  });
}
