import 'package:flutter_test/flutter_test.dart';
import 'package:artavia/core/utils/finance_calc.dart';

Map<String, dynamic> tx(String type, int amount, DateTime date, {int? cat}) => {
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'category_id': cat,
    };

void main() {
  group('computeNetWorth', () {
    test('ignores excluded accounts and splits assets/liabilities', () {
      final worth = computeNetWorth([
        {'balance': 1000, 'is_excluded': 0},
        {'balance': -300, 'is_excluded': 0},
        {'balance': 5000, 'is_excluded': 1},
        {'balance': 200, 'exclude_from_total': true},
      ]);
      expect(worth.asset, 1000);
      expect(worth.liability, 300);
      expect(worth.net, 700);
    });

    test('empty list is zero', () {
      expect(computeNetWorth([]).net, 0);
    });
  });

  group('buildTrend', () {
    test('year mode has 12 monthly buckets and does not mix days', () {
      final points = buildTrend([
        tx('pengeluaran', 100, DateTime(2026, 1, 5)),
        tx('pengeluaran', 50, DateTime(2026, 2, 5)),
        tx('pemasukan', 999, DateTime(2026, 2, 5)),
      ], TrendMode.year, DateTime(2026), DateTime(2027));
      expect(points, hasLength(12));
      expect(points[0].amount, 100);
      expect(points[1].amount, 50);
      expect(points[0].label, 'Jan');
    });

    test('week mode has 7 day buckets across a month boundary', () {
      final start = DateTime(2026, 9, 28); // Monday
      final points = buildTrend([
        tx('pengeluaran', 10, DateTime(2026, 9, 28, 9)),
        tx('pengeluaran', 20, DateTime(2026, 10, 1, 21)),
        tx('pengeluaran', 99, DateTime(2026, 10, 5)), // next week
      ], TrendMode.week, start, start.add(const Duration(days: 7)));
      expect(points, hasLength(7));
      expect(points.first.label, 'Sen');
      expect(points[0].amount, 10);
      expect(points[3].amount, 20);
      expect(points.fold<int>(0, (s, p) => s + p.amount), 30);
    });

    test('month mode follows a custom period range', () {
      final points = buildTrend([
        tx('pengeluaran', 5, DateTime(2026, 9, 25)),
      ], TrendMode.month, DateTime(2026, 9, 25), DateTime(2026, 10, 25));
      expect(points, hasLength(30));
      expect(points.first.amount, 5);
      expect(points.first.label, '25');
    });
  });

  test('startOfWeek returns Monday', () {
    expect(startOfWeek(DateTime(2026, 10, 25)), DateTime(2026, 10, 19));
  });

  test('matchesTypeFilter handles Transfer (FR-010)', () {
    expect(matchesTypeFilter('transfer', 'Transfer'), isTrue);
    expect(matchesTypeFilter('pengeluaran', 'Transfer'), isFalse);
    expect(matchesTypeFilter('pemasukan', 'Semua'), isTrue);
  });

  test('summarizeBudget counts categories over their limit', () {
    final used = expenseByCategoryId([
      tx('pengeluaran', 700, DateTime(2026), cat: 1),
      tx('pengeluaran', 100, DateTime(2026), cat: 2),
      tx('pemasukan', 5000, DateTime(2026), cat: 1),
    ]);
    final summary = summarizeBudget([
      {'category_id': 1, 'budget_amount': 500},
      {'category_id': 2, 'budget_amount': 500},
    ], used);
    expect(summary.total, 1000);
    expect(summary.used, 800);
    expect(summary.overCount, 1);
  });
}
