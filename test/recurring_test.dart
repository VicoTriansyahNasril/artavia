import 'package:flutter_test/flutter_test.dart';
import 'package:artavia/core/models/recurring_rule.dart';
import 'package:artavia/core/services/recurring_service.dart';

RecurringRule rule(RecurringFrequency f, DateTime start, {DateTime? last}) =>
    RecurringRule(
      type: 'pengeluaran',
      amount: 1000,
      categoryId: 1,
      accountId: 1,
      frequency: f,
      startDate: start,
      lastRunDate: last,
    );

void main() {
  test('monthly rule catches up every missed month once', () {
    final dates = dueDates(
        rule(RecurringFrequency.monthly, DateTime(2026, 8, 1)),
        DateTime(2026, 10, 25));
    expect(dates,
        [DateTime(2026, 8, 1), DateTime(2026, 9, 1), DateTime(2026, 10, 1)]);
  });

  test('last_run_date prevents duplicates', () {
    final dates = dueDates(
      rule(RecurringFrequency.monthly, DateTime(2026, 8, 1),
          last: DateTime(2026, 10, 1)),
      DateTime(2026, 10, 25),
    );
    expect(dates, isEmpty);
  });

  test('day 31 is clamped to short months and returns to 31', () {
    final dates = dueDates(
        rule(RecurringFrequency.monthly, DateTime(2026, 1, 31)),
        DateTime(2026, 3, 31));
    expect(dates,
        [DateTime(2026, 1, 31), DateTime(2026, 2, 28), DateTime(2026, 3, 31)]);
  });

  test('weekly and daily steps', () {
    expect(
      dueDates(rule(RecurringFrequency.weekly, DateTime(2026, 10, 1)),
          DateTime(2026, 10, 15)),
      [DateTime(2026, 10, 1), DateTime(2026, 10, 8), DateTime(2026, 10, 15)],
    );
    expect(
      dueDates(rule(RecurringFrequency.daily, DateTime(2026, 10, 24)),
          DateTime(2026, 10, 25)),
      hasLength(2),
    );
  });

  test('future start date is not due yet', () {
    final r = rule(RecurringFrequency.monthly, DateTime(2026, 11, 1));
    expect(dueDates(r, DateTime(2026, 10, 25)), isEmpty);
    expect(nextOccurrence(r), DateTime(2026, 11, 1));
  });

  test('very old rules are capped per run', () {
    final dates = dueDates(
        rule(RecurringFrequency.daily, DateTime(2020)), DateTime(2026, 10, 25));
    expect(dates, hasLength(maxOccurrencesPerRun));
  });
}
