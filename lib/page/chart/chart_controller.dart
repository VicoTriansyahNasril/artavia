import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:artavia/core/database/database_helper.dart';

class ChartController extends GetxController {
  final currentTab = 'Bulan'.obs;
  final currentDate = DateTime.now().obs;

  final expenses = <Map<String, dynamic>>[].obs;
  final dailySpots = <FlSpot>[].obs;
  final totalExpense = 0.obs;
  final totalIncome = 0.obs;
  final avgExpense = 0.obs;

  String get currentDateLabel {
    final d = currentDate.value;
    if (currentTab.value == 'Pekan') {
      return 'Pekan ini';
    } else if (currentTab.value == 'Bulan') {
      final months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${months[d.month]} ${d.year}';
    } else {
      return d.year.toString();
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void changeTab(String tab) {
    currentTab.value = tab;
    loadData();
  }

  void prevPeriod() {
    final d = currentDate.value;
    if (currentTab.value == 'Bulan') {
      currentDate.value = DateTime(d.year, d.month - 1);
    } else if (currentTab.value == 'Tahun') {
      currentDate.value = DateTime(d.year - 1);
    }
    loadData();
  }

  void nextPeriod() {
    final d = currentDate.value;
    if (currentTab.value == 'Bulan') {
      currentDate.value = DateTime(d.year, d.month + 1);
    } else if (currentTab.value == 'Tahun') {
      currentDate.value = DateTime(d.year + 1);
    }
    loadData();
  }

  Future<void> loadData() async {
    List<Map<String, dynamic>> transactions;

    if (currentTab.value == 'Bulan') {
      transactions = await DatabaseHelper.instance.readTransactionsByMonth(
          currentDate.value.year, currentDate.value.month);
    } else if (currentTab.value == 'Tahun') {
      transactions = await DatabaseHelper.instance.readAllTransactions();
      transactions = transactions
          .where((t) =>
              DateTime.parse(t['date'] as String).year ==
              currentDate.value.year)
          .toList();
    } else {
      // Pekan – last 7 days
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      transactions = await DatabaseHelper.instance.readAllTransactions();
      transactions = transactions.where((t) {
        final d = DateTime.parse(t['date'] as String);
        return d.isAfter(weekAgo) && d.isBefore(now.add(const Duration(days: 1)));
      }).toList();
    }

    // Aggregate by category (expenses only)
    final Map<String, int> byCat = {};
    final Map<int, int> byDay = {};
    int totEx = 0;
    int totIn = 0;

    for (var t in transactions) {
      final amt = t['amount'] as int;
      final type = t['type'] as String;
      final date = DateTime.parse(t['date'] as String);

      if (type == 'pengeluaran') {
        totEx += amt;
        final cat = (t['categoryName'] as String?) ?? 'Lainnya';
        byCat[cat] = (byCat[cat] ?? 0) + amt;
        final day = date.day;
        byDay[day] = (byDay[day] ?? 0) + amt;
      } else if (type == 'pemasukan') {
        totIn += amt;
      }
    }

    totalExpense.value = totEx;
    totalIncome.value = totIn;

    // Build category list sorted by amount desc
    final catColors = [
      0xFFFF9800, 0xFF4CAF50, 0xFF9C27B0, 0xFFF44336,
      0xFF2196F3, 0xFFE91E63, 0xFF00BCD4, 0xFFFFEB3B,
    ];
    final catIcons = [
      Icons.shopping_cart, Icons.restaurant, Icons.directions_bus,
      Icons.medical_services, Icons.home, Icons.movie,
      Icons.fitness_center, Icons.category,
    ];

    final sorted = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int idx = 0;
    final expList = <Map<String, dynamic>>[];
    for (var e in sorted) {
      final percent =
          totEx > 0 ? (e.value / totEx * 100).toStringAsFixed(1) : '0.0';
      expList.add({
        'name': e.key,
        'amount': e.value,
        'percent': double.tryParse(percent) ?? 0.0,
        'color': catColors[idx % catColors.length],
        'icon': catIcons[idx % catIcons.length],
      });
      idx++;
    }
    expenses.value = expList;

    // Build daily spots for line chart
    if (byDay.isNotEmpty) {
      final spotList = byDay.entries
          .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
          .toList()
        ..sort((a, b) => a.x.compareTo(b.x));
      dailySpots.value = spotList;

      final daysWithData = byDay.length;
      avgExpense.value = daysWithData > 0 ? totEx ~/ daysWithData : 0;
    } else {
      dailySpots.value = [];
      avgExpense.value = 0;
    }
  }
}
