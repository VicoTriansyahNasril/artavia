import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/services/privacy_service.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/finance_calc.dart';
import 'package:artavia/page/report/report_controller.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// Laporan tab (board "Laporan").
class ReportScreen extends GetView<ReportController> {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.loadData,
      backgroundColor: colorCard,
      color: colorAccent,
      child: Obx(() {
        final empty = controller.total.value == 0;
        // Children are plain widgets: read what they show so this rebuilds.
        PrivacyService.to.masked.value;
        controller
          ..previousTotal.value
          ..bars.length
          ..shares.length
          ..breakdown.length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          children: [
            KSegment<TrendMode>(
              items: const {
                TrendMode.week: 'Minggu',
                TrendMode.month: 'Bulan',
                TrendMode.year: 'Tahun',
              },
              value: controller.mode.value,
              onChanged: controller.changeMode,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                KIconButton(
                  icon: LucideIcons.chevronLeft,
                  semanticLabel: 'Periode sebelumnya',
                  onPressed: () => controller.shiftPeriod(-1),
                ),
                Expanded(
                  child: Text(controller.periodLabel,
                      textAlign: TextAlign.center,
                      style: AppText.title3.copyWith(color: colorText)),
                ),
                KIconButton(
                  icon: LucideIcons.chevronRight,
                  semanticLabel: 'Periode berikutnya',
                  onPressed: () => controller.shiftPeriod(1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const _TotalCard(),
            if (PrivacyService.to.masked.value) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(LucideIcons.eyeOff, size: 14, color: colorGrey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                        'Nominal disembunyikan. Persentase tetap ditampilkan.',
                        style: AppText.caption.muted),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const _TrendCard(),
            if (empty)
              EmptyState(
                icon: LucideIcons.chartPie,
                title: controller.isIncome.value
                    ? 'Belum ada pemasukan'
                    : 'Belum ada pengeluaran',
                body: 'Tidak ada data pada periode ini.',
              )
            else ...[
              const SizedBox(height: 12),
              const _DonutCard(),
              const _Breakdown(),
            ],
          ],
        );
      }),
    );
  }
}

class _TotalCard extends GetView<ReportController> {
  const _TotalCard();

  @override
  Widget build(BuildContext context) {
    final income = controller.isIncome.value;
    final change = controller.changePercent;
    // Spending less, or earning more, is the good direction.
    final good = change != null && (income ? change > 0 : change < 0);
    final money = CurrencyService.to;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(income ? 'Total pemasukan' : 'Total pengeluaran',
                    style: AppText.caption.onGlass),
              ),
              KChip(
                label: income ? 'Pemasukan' : 'Pengeluaran',
                icon: LucideIcons.arrowLeftRight,
                selected: true,
                onTap: controller.toggleKind,
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('Rp ', style: AppText.currencyPrefix.onGlass),
                Text(money.digits(controller.total.value),
                    style: AppText.amountL.copyWith(color: colorText)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (change != null) ...[
                Icon(
                    change < 0
                        ? LucideIcons.trendingDown
                        : LucideIcons.trendingUp,
                    size: 16,
                    color: good ? colorIncome : colorDanger),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  change == null
                      ? 'Belum ada data ${controller.previousLabel} untuk dibandingkan'
                      : change == 0
                          ? 'Sama dengan ${controller.previousLabel}'
                          : '${change.abs()}% ${change < 0 ? 'lebih rendah' : 'lebih tinggi'} '
                              'dari ${controller.previousLabel} '
                              '(${money.money(controller.previousTotal.value)})',
                  style: AppText.caption.onGlass,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Trend bars: current bar in accent, future bars dashed outlines.
class _TrendCard extends GetView<ReportController> {
  const _TrendCard();

  @override
  Widget build(BuildContext context) {
    final bars = controller.bars;
    final max = bars.fold<int>(0, (m, b) => b.amount > m ? b.amount : m);
    final money = CurrencyService.to;
    return KCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tren',
              style: AppText.bodySmall.w600.copyWith(color: colorText)),
          const SizedBox(height: 12),
          SizedBox(
            height: 132,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final b in bars)
                  Expanded(
                    child: Semantics(
                      label: '${b.label} ${money.money(b.amount)}',
                      excludeSemantics: true,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: b.future
                                    ? 0.35
                                    : max == 0
                                        ? 0.02
                                        : (b.amount / max).clamp(0.02, 1.0),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: bars.length > 7 ? 3 : 6),
                                  child: b.future
                                      ? CustomPaint(
                                          painter: _DashedBar(colorDivider),
                                          child: const SizedBox.expand(),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            color: b.current
                                                ? colorAccent
                                                : colorSurfaceSelected,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(b.label,
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              textScaler: TextScaler.noScaling,
                              style: AppText.caption.copyWith(
                                  color: b.current ? colorAccent : colorGrey,
                                  fontWeight: b.current
                                      ? FontWeight.w600
                                      : FontWeight.w400)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBar extends CustomPainter {
  final Color color;
  _DashedBar(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rect =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in (Path()..addRRect(rect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 8) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBar old) => old.color != color;
}

class _DonutCard extends GetView<ReportController> {
  const _DonutCard();

  @override
  Widget build(BuildContext context) {
    final shares = controller.shares;
    return KCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 44,
                  startDegreeOffset: -90,
                  sections: [
                    for (final s in shares)
                      PieChartSectionData(
                        color: s.color,
                        value: s.amount.toDouble(),
                        radius: 16,
                        showTitle: false,
                      ),
                  ],
                )),
                Text(CurrencyService.to.short(controller.total.value),
                    style: AppText.label.copyWith(color: colorText)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                for (final s in shares)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: s.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(s.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  AppText.caption.copyWith(color: colorText)),
                        ),
                        Text('${s.percent.round()}%',
                            style: AppText.caption.muted),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Breakdown extends GetView<ReportController> {
  const _Breakdown();

  @override
  Widget build(BuildContext context) {
    final items = controller.breakdown;
    final max = items.isEmpty ? 1 : items.first.amount;
    final money = CurrencyService.to;
    return ListGroup(
      title: 'Rincian kategori',
      children: [
        for (final c in items)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CategoryIcon.round(
                  iconKey: c.iconKey,
                  iconPath: c.iconPath,
                  iconCode: c.iconCode,
                  color: c.color,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body.copyWith(color: colorText)),
                          ),
                          Text(money.money(c.amount),
                              style:
                                  AppText.rowAmount.copyWith(color: colorText)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      KProgress(
                          value: max == 0 ? 0 : c.amount / max, height: 4),
                      const SizedBox(height: 4),
                      Text(
                          '${c.count} transaksi · ${c.percent.toStringAsFixed(c.percent < 10 ? 1 : 0).replaceAll('.', ',')}%',
                          style: AppText.caption.muted),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
