import 'package:flutter/material.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:artavia/page/chart/chart_controller.dart';
import 'package:artavia/widgets/commons/common.dart';

class ChartScreen extends GetView<ChartController> {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterTabs(),
        Expanded(
          child: Obx(() {
            if (controller.expenses.isEmpty && controller.dailySpots.isEmpty) {
              return _buildEmptyState();
            }
            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  if (controller.expenses.isNotEmpty) _buildDonutChart(),
                  if (controller.dailySpots.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildLineChart(),
                  ],
                  const SizedBox(height: 16),
                  if (controller.expenses.isNotEmpty) _buildCategoryList(),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart, size: 64, color: colorGrey.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text('Belum ada data transaksi',
              style: TextStyle(color: colorGrey, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Tambahkan transaksi untuk melihat grafik',
              style: TextStyle(color: colorGrey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: colorBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildTab('Pekan'),
              const SizedBox(width: 16),
              _buildTab('Bulan'),
              const SizedBox(width: 16),
              _buildTab('Tahun'),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => controller.prevPeriod(),
                child: const Icon(Icons.chevron_left,
                    color: colorGrey, size: 20),
              ),
              const SizedBox(width: 4),
              Obx(() => Text(
                    controller.currentDateLabel,
                    style: const TextStyle(
                        color: colorWhite, fontWeight: FontWeight.bold),
                  )),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => controller.nextPeriod(),
                child: const Icon(Icons.chevron_right,
                    color: colorGrey, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title) {
    return Obx(() {
      final isSelected = controller.currentTab.value == title;
      return GestureDetector(
        onTap: () => controller.changeTab(title),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? colorWhite : colorGrey,
                fontSize: 16,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 3,
                width: 20,
                color: colorAccent,
              )
          ],
        ),
      );
    });
  }

  Widget _buildDonutChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pengeluaran per Kategori',
                  style: TextStyle(
                      color: colorWhite, fontWeight: FontWeight.bold)),
              Obx(() => Text(
                    CurrencyService.to.formatWithoutSymbol(
                        controller.totalExpense.value),
                    style: const TextStyle(
                        color: colorExpense, fontWeight: FontWeight.bold),
                  )),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Obx(() {
              final sections = controller.expenses
                  .map((ex) => PieChartSectionData(
                        color: Color(ex['color'] as int),
                        value: (ex['percent'] as double),
                        title:
                            '${(ex['percent'] as double).toStringAsFixed(0)}%',
                        radius: 40,
                        titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorWhite),
                      ))
                  .toList();
              return PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 50,
                  sectionsSpace: 2,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tren Pengeluaran Harian',
              style: TextStyle(
                  color: colorWhite, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Obx(() => Text(
                'Total: ${CurrencyService.to.formatWithoutSymbol(controller.totalExpense.value)} | '
                'Rata-rata: ${CurrencyService.to.formatWithoutSymbol(controller.avgExpense.value)}',
                style:
                    const TextStyle(color: colorGrey, fontSize: 12),
              )),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Obx(() {
              final spots = controller.dailySpots;
              if (spots.isEmpty) return const SizedBox.shrink();
              return LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          if (value % 5 == 0 || value == 1) {
                            return Text('${value.toInt()}',
                                style: const TextStyle(
                                    color: colorGrey, fontSize: 10));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: colorExpense,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorExpense.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return Container(
      color: colorCard,
      child: Obx(() {
        return Column(
          children: controller.expenses.map((ex) {
            final color = Color(ex['color'] as int);
            final icon = ex['icon'] as IconData;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(icon, color: color, size: 20),
              ),
              title: Text(ex['name'] as String,
                  style: const TextStyle(color: colorWhite)),
              subtitle: Text('${ex['percent']}%',
                  style: const TextStyle(color: colorGrey)),
              trailing: Text(
                CurrencyService.to
                    .formatWithoutSymbol(ex['amount'] as num? ?? 0),
                style: const TextStyle(
                    color: colorWhite, fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
        );
      }),
    );
  }
}
