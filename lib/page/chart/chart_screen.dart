import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/finance_calc.dart';
import 'package:artavia/model/transaction_model.dart';
import 'package:artavia/page/chart/chart_controller.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/transaction/transaction_item.dart';

/// The single analysis tab (FR-020): summary, categories, trend.
class ChartScreen extends GetView<ChartController> {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _PeriodBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.loadData,
            backgroundColor: colorCard,
            child: Obx(() => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  children: controller.hasData.value
                      ? const [
                          _SummaryCard(),
                          SizedBox(height: 12),
                          _CategoryCard(),
                          SizedBox(height: 12),
                          _TrendCard(),
                        ]
                      : const [_SummaryCard(), _EmptyState()],
                )),
          ),
        ),
      ],
    );
  }
}

class _PeriodBar extends GetView<ChartController> {
  const _PeriodBar();

  static const _modes = {
    TrendMode.week: 'Pekan',
    TrendMode.month: 'Bulan',
    TrendMode.year: 'Tahun',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
      child: Obx(() => Row(
            children: [
              ..._modes.entries.map((e) {
                final selected = controller.mode.value == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(e.value),
                    selected: selected,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    labelStyle: TextStyle(
                        color: selected ? colorAccent : colorGrey,
                        fontSize: 13),
                    onSelected: (_) => controller.changeMode(e.key),
                  ),
                );
              }),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left_rounded, color: colorGrey),
                onPressed: () => controller.shiftPeriod(-1),
              ),
              Text(controller.periodLabel,
                  style: const TextStyle(
                      color: colorText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right_rounded, color: colorGrey),
                onPressed: () => controller.shiftPeriod(1),
              ),
            ],
          )),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
            color: colorCard, borderRadius: BorderRadius.circular(12)),
        child: child,
      );
}

class _SummaryCard extends GetView<ChartController> {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Obx(() => Row(
            children: [
              _stat('Pengeluaran', controller.totalExpense.value, colorExpense),
              _stat('Pemasukan', controller.totalIncome.value, colorIncome),
              _stat(
                  'Saldo',
                  controller.totalIncome.value - controller.totalExpense.value,
                  colorText),
            ],
          )),
    );
  }

  Widget _stat(String label, int value, Color color) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: colorGrey, fontSize: 12)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(CurrencyService.to.formatWithoutSymbol(value),
                  style: TextStyle(
                      color: color, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(Icons.insights_outlined, size: 48, color: colorGrey),
          SizedBox(height: 16),
          Text('Belum ada data pada periode ini',
              style: TextStyle(
                  color: colorText, fontSize: 15, fontWeight: FontWeight.w500)),
          SizedBox(height: 6),
          Text('Tambahkan transaksi untuk melihat analisis',
              style: TextStyle(color: colorGrey, fontSize: 13)),
        ],
      ),
    );
  }
}

class _CategoryCard extends GetView<ChartController> {
  const _CategoryCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final slices = controller.slices;
      if (slices.isEmpty) {
        return const _Card(
          child: Text('Belum ada pengeluaran pada periode ini',
              style: TextStyle(color: colorGrey)),
        );
      }
      return _Card(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Pengeluaran per Kategori',
                  style:
                      TextStyle(color: colorText, fontWeight: FontWeight.w600)),
            ),
            SizedBox(
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 58,
                    sections: slices
                        .map((s) => PieChartSectionData(
                              color: s.color,
                              value: s.amount.toDouble(),
                              radius: 18,
                              showTitle: false,
                            ))
                        .toList(),
                  )),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Total',
                        style: TextStyle(color: colorGrey, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                        CurrencyService.to
                            .formatWithoutSymbol(controller.totalExpense.value),
                        style: const TextStyle(
                            color: colorText,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ]),
                ],
              ),
            ),
            ...slices.map((s) => _SliceTile(slice: s)),
          ],
        ),
      );
    });
  }
}

class _SliceTile extends StatelessWidget {
  final CategorySlice slice;

  const _SliceTile({required this.slice});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showTransactions(slice),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          children: [
            Row(children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: slice.color.withValues(alpha: 0.14),
                child: CategoryIcon(
                    iconCode: slice.iconCode,
                    iconPath: slice.iconPath,
                    color: slice.color,
                    size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(slice.name,
                    style: const TextStyle(color: colorText, fontSize: 14)),
              ),
              Text('${slice.percent.toStringAsFixed(1)}%',
                  style: const TextStyle(color: colorGrey, fontSize: 12)),
              const SizedBox(width: 12),
              Text(CurrencyService.to.formatWithoutSymbol(slice.amount),
                  style: const TextStyle(
                      color: colorText, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: slice.percent / 100,
                  minHeight: 4,
                  backgroundColor: colorSurface,
                  valueColor: AlwaysStoppedAnimation(slice.color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactions(CategorySlice slice) {
    final items = slice.transactions.map(TransactionModel.fromDbRow).toList();
    Get.bottomSheet(
      ConstrainedBox(
        constraints: BoxConstraints(maxHeight: Get.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: colorDivider, borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              title: Text(slice.name,
                  style: const TextStyle(
                      color: colorText,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
              trailing: Text('${items.length} transaksi',
                  style: const TextStyle(color: colorGrey)),
            ),
            const Divider(),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(indent: 68),
                itemBuilder: (_, i) =>
                    TransactionItem(tx: items[i], showDate: true),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _TrendCard extends GetView<ChartController> {
  const _TrendCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Obx(() {
        final points = controller.trend;
        final step = (points.length / 6).ceil().clamp(1, 31);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tren Pengeluaran',
                style:
                    TextStyle(color: colorText, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
                'Rata-rata ${CurrencyService.to.formatWithoutSymbol(controller.avgExpense.value)}'
                ' per ${controller.mode.value == TrendMode.year ? 'bulan' : 'hari'} aktif',
                style: const TextStyle(color: colorGrey, fontSize: 12)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: LineChart(LineChartData(
                minY: 0,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => colorSurface,
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              '${points[s.x.toInt()].label}\n'
                              '${CurrencyService.to.formatWithoutSymbol(s.y)}',
                              const TextStyle(color: colorText, fontSize: 12),
                            ))
                        .toList(),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= points.length || i % step != 0) {
                          return const SizedBox.shrink();
                        }
                        return Text(points[i].label,
                            style: const TextStyle(
                                color: colorGrey, fontSize: 10));
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: points
                        .map((p) => FlSpot(p.x.toDouble(), p.amount.toDouble()))
                        .toList(),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: colorAccent,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colorAccent.withValues(alpha: 0.10),
                    ),
                  ),
                ],
              )),
            ),
          ],
        );
      }),
    );
  }
}
