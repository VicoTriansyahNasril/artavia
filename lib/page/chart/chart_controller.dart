import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/utils/date_format.dart';
import 'package:artavia/core/utils/finance_calc.dart';
import 'package:artavia/widgets/commons/common.dart';

/// One slice of the expense donut (top categories + "Lain-lain").
class CategorySlice {
  final String name;
  final int amount;
  final double percent;
  final Color color;
  final int? iconCode;
  final String? iconPath;
  final List<Map<String, dynamic>> transactions;

  const CategorySlice({
    required this.name,
    required this.amount,
    required this.percent,
    required this.color,
    required this.iconCode,
    required this.iconPath,
    required this.transactions,
  });
}

class ChartController extends GetxController {
  static const _maxSlices = 5;

  final mode = TrendMode.month.obs;
  final weekStart = startOfWeek(DateTime.now()).obs;
  final year = DateTime.now().year.obs;

  final slices = <CategorySlice>[].obs;
  final trend = <TrendPoint>[].obs;
  final totalExpense = 0.obs;
  final totalIncome = 0.obs;
  final avgExpense = 0.obs;
  final hasData = false.obs;

  PeriodService get _period => PeriodService.to;

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
        final end = weekStart.value.add(const Duration(days: 6));
        return '${weekStart.value.day} ${IdNames.monthShort(weekStart.value.month)}'
            ' – ${end.day} ${IdNames.monthShort(end.month)}';
      case TrendMode.month:
        return _period.active.value.label;
      case TrendMode.year:
        return '${year.value}';
    }
  }

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
    final start = rangeStart;
    final end = rangeEnd;
    final rows =
        await DatabaseHelper.instance.readTransactionsByRange(start, end);

    var expense = 0;
    var income = 0;
    for (final t in rows) {
      final amount = t['amount'] as int;
      if (t['type'] == 'pengeluaran') expense += amount;
      if (t['type'] == 'pemasukan') income += amount;
    }
    totalExpense.value = expense;
    totalIncome.value = income;
    hasData.value = rows.isNotEmpty;
    slices.value = _buildSlices(rows, expense);

    final points = buildTrend(rows, mode.value, start, end);
    trend.value = points;
    final active = points.where((p) => p.amount > 0).length;
    avgExpense.value = active == 0 ? 0 : expense ~/ active;
  }

  List<CategorySlice> _buildSlices(List<Map<String, dynamic>> rows, int total) {
    final byCategory = <String, List<Map<String, dynamic>>>{};
    for (final t in rows.where((t) => t['type'] == 'pengeluaran')) {
      final name = t['categoryName'] as String? ?? 'Lainnya';
      byCategory.putIfAbsent(name, () => []).add(t);
    }
    int sum(List<Map<String, dynamic>> list) =>
        list.fold(0, (s, t) => s + (t['amount'] as int));
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => sum(b.value).compareTo(sum(a.value)));

    final overflow = sorted.length > _maxSlices;
    final head = overflow ? sorted.take(_maxSlices - 1).toList() : sorted;
    final result = <CategorySlice>[];
    for (var i = 0; i < head.length; i++) {
      final first = head[i].value.first;
      final colorVal = first['categoryColorVal'] as int?;
      result.add(_slice(
        head[i].key,
        head[i].value,
        total,
        colorVal != null && colorVal != 0 ? Color(colorVal) : paletteColorAt(i),
        first['categoryIconCode'] as int?,
        first['categoryIconPath'] as String?,
      ));
    }
    if (overflow) {
      final rest = sorted.skip(_maxSlices - 1).expand((e) => e.value).toList();
      result.add(_slice('Lain-lain', rest, total, colorGrey,
          Icons.more_horiz.codePoint, null));
    }
    return result;
  }

  CategorySlice _slice(String name, List<Map<String, dynamic>> txs, int total,
      Color color, int? iconCode, String? iconPath) {
    final amount = txs.fold<int>(0, (s, t) => s + (t['amount'] as int));
    return CategorySlice(
      name: name,
      amount: amount,
      percent: total == 0 ? 0 : amount / total * 100,
      color: color,
      iconCode: iconCode,
      iconPath: iconPath,
      transactions: txs,
    );
  }
}
