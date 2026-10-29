import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/utils/date_format.dart';
import 'package:artavia/core/utils/finance_calc.dart';
import 'package:artavia/widgets/commons/common.dart';

/// One category in the donut / breakdown list.
class CategoryShare {
  final String name;
  final int amount;
  final int count;
  final double percent;
  final Color color;
  final String? iconKey;
  final String? iconPath;
  final int? iconCode;

  const CategoryShare({
    required this.name,
    required this.amount,
    required this.count,
    required this.percent,
    required this.color,
    this.iconKey,
    this.iconPath,
    this.iconCode,
  });
}

/// One bar of the trend chart.
class TrendBar {
  final String label;
  final int amount;
  final bool current;
  final bool future;

  const TrendBar(this.label, this.amount,
      {this.current = false, this.future = false});
}

/// Laporan tab (FR-019): Minggu/Bulan/Tahun, pengeluaran ↔ pemasukan,
/// comparison with the previous period, trend bars, donut (top 5 +
/// Lainnya) and the category breakdown.
class ReportController extends GetxController {
  static const _topSlices = 5;

  final mode = TrendMode.month.obs;
  final isIncome = false.obs;
  final weekStart = startOfWeek(DateTime.now()).obs;
  final year = DateTime.now().year.obs;

  final total = 0.obs;
  final previousTotal = 0.obs;
  final bars = <TrendBar>[].obs;
  final shares = <CategoryShare>[].obs;
  final breakdown = <CategoryShare>[].obs;
  final isLoading = false.obs;

  PeriodService get _period => PeriodService.to;
  String get _type => isIncome.value ? 'pemasukan' : 'pengeluaran';

  DateTime get rangeStart => switch (mode.value) {
        TrendMode.week => weekStart.value,
        TrendMode.month => _period.active.value.start,
        TrendMode.year => DateTime(year.value),
      };

  DateTime get rangeEnd => switch (mode.value) {
        TrendMode.week => weekStart.value.add(const Duration(days: 7)),
        TrendMode.month => _period.active.value.end,
        TrendMode.year => DateTime(year.value + 1),
      };

  String get periodLabel {
    switch (mode.value) {
      case TrendMode.week:
        final s = weekStart.value;
        final e = s.add(const Duration(days: 6));
        return '${s.day} ${IdNames.monthShort(s.month)} – '
            '${e.day} ${IdNames.monthShort(e.month)} ${e.year}';
      case TrendMode.month:
        return _period.active.value.longLabel;
      case TrendMode.year:
        return '${year.value}';
    }
  }

  String get previousLabel => switch (mode.value) {
        TrendMode.week => 'minggu lalu',
        TrendMode.month => 'bulan lalu',
        TrendMode.year => 'tahun lalu',
      };

  /// Change vs the previous period in percent; null when nothing to compare.
  int? get changePercent => previousTotal.value == 0
      ? null
      : ((total.value - previousTotal.value) * 100 / previousTotal.value)
          .round();

  @override
  void onInit() {
    super.onInit();
    ever(_period.active, (_) {
      if (mode.value == TrendMode.month) loadData();
    });
    loadData();
  }

  void changeMode(TrendMode value) {
    mode.value = value;
    loadData();
  }

  void toggleKind() {
    isIncome.value = !isIncome.value;
    loadData();
  }

  void shiftPeriod(int step) {
    switch (mode.value) {
      case TrendMode.week:
        weekStart.value = weekStart.value.add(Duration(days: 7 * step));
      case TrendMode.month:
        _period.shift(step); // reloads via ever()
        return;
      case TrendMode.year:
        year.value += step;
    }
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      final db = DatabaseHelper.instance;
      final (prevStart, prevEnd) = _previousRange();
      final (trendStart, trendEnd) = _trendRange();
      final from =
          [prevStart, trendStart].reduce((a, b) => a.isBefore(b) ? a : b);
      final to = [rangeEnd, trendEnd].reduce((a, b) => a.isAfter(b) ? a : b);
      // Parse each date once; everything below filters on these.
      final rows = [
        for (final r in await db.readTransactionsByRange(from, to))
          if (r['type'] == _type) (DateTime.parse(r['date'] as String), r),
      ];
      _dated = rows;

      final current = [
        for (final (d, r) in rows)
          if (!d.isBefore(rangeStart) && d.isBefore(rangeEnd)) r,
      ];
      total.value = _sum(current);
      previousTotal.value = _sumIn(prevStart, prevEnd);
      bars.value = _bars();
      final all = _byCategory(current, total.value);
      breakdown.value = all;
      shares.value = _top(all);
    } finally {
      isLoading.value = false;
    }
  }

  static int _sum(Iterable<Map<String, dynamic>> rows) =>
      rows.fold(0, (s, r) => s + (r['amount'] as int));

  List<(DateTime, Map<String, dynamic>)> _dated = const [];

  int _sumIn(DateTime s, DateTime e) {
    var total = 0;
    for (final (d, r) in _dated) {
      if (!d.isBefore(s) && d.isBefore(e)) total += r['amount'] as int;
    }
    return total;
  }

  (DateTime, DateTime) _previousRange() => switch (mode.value) {
        TrendMode.week => (
            weekStart.value.subtract(const Duration(days: 7)),
            weekStart.value
          ),
        TrendMode.month => (
            _period.active.value.shift(-1).start,
            _period.active.value.start
          ),
        TrendMode.year => (DateTime(year.value - 1), DateTime(year.value)),
      };

  /// Week: the 7 days; month: 6 periods ending at the active one; year: 12
  /// calendar months.
  (DateTime, DateTime) _trendRange() => switch (mode.value) {
        TrendMode.month => (
            _period.active.value.shift(-5).start,
            _period.active.value.end
          ),
        _ => (rangeStart, rangeEnd),
      };

  List<TrendBar> _bars() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sumIn = _sumIn;

    switch (mode.value) {
      case TrendMode.week:
        return [
          for (var i = 0; i < 7; i++)
            () {
              final d = weekStart.value.add(Duration(days: i));
              return TrendBar(
                  IdNames.dayShort(d), sumIn(d, d.add(const Duration(days: 1))),
                  current: d == today, future: d.isAfter(today));
            }(),
        ];
      case TrendMode.month:
        final active = _period.active.value;
        final nowPeriod = Period.containing(now, active.start.day);
        return [
          for (var i = -5; i <= 0; i++)
            () {
              final p = active.shift(i);
              return TrendBar(
                  IdNames.monthShort(p.month), sumIn(p.start, p.end),
                  current:
                      p.year == nowPeriod.year && p.month == nowPeriod.month,
                  future: p.start.isAfter(now));
            }(),
        ];
      case TrendMode.year:
        return [
          for (var m = 1; m <= 12; m++)
            TrendBar(IdNames.monthShort(m),
                sumIn(DateTime(year.value, m), DateTime(year.value, m + 1)),
                current: year.value == now.year && m == now.month,
                future: DateTime(year.value, m).isAfter(now)),
        ];
    }
  }

  List<CategoryShare> _byCategory(List<Map<String, dynamic>> rows, int total) {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final r in rows) {
      groups
          .putIfAbsent(
              r['categoryName'] as String? ?? 'Tanpa kategori', () => [])
          .add(r);
    }
    final totals = {for (final e in groups.entries) e.key: _sum(e.value)};
    final list = groups.entries.toList()
      ..sort((a, b) => totals[b.key]!.compareTo(totals[a.key]!));
    return [
      for (var i = 0; i < list.length; i++)
        () {
          final first = list[i].value.first;
          final amount = totals[list[i].key]!;
          return CategoryShare(
            name: list[i].key,
            amount: amount,
            count: list[i].value.length,
            percent: total == 0 ? 0 : amount * 100 / total,
            color: themedColor(first['categoryColorVal'] as int?,
                fallbackIndex: i),
            iconKey: first['categoryIconKey'] as String?,
            iconPath: first['categoryIconPath'] as String?,
            iconCode: first['categoryIconCode'] as int?,
          );
        }(),
    ];
  }

  /// Donut: the top 5 plus "Lainnya" for the rest.
  List<CategoryShare> _top(List<CategoryShare> all) {
    if (all.length <= _topSlices) return all;
    final rest = all.skip(_topSlices);
    return [
      ...all.take(_topSlices),
      CategoryShare(
        name: 'Lainnya',
        amount: rest.fold(0, (s, c) => s + c.amount),
        count: rest.fold(0, (s, c) => s + c.count),
        percent: rest.fold(0.0, (s, c) => s + c.percent),
        color: colorGrey,
        iconKey: 'lainnya',
      ),
    ];
  }
}
