import 'package:flutter/material.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:artavia/page/report/report_controller.dart';
import 'package:artavia/widgets/commons/common.dart';

class ReportScreen extends GetView<ReportController> {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              children: [
                _buildAnalisisTab(),
                _buildRekeningTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: colorBackground,
      child: const TabBar(
        indicatorColor: colorAccent,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: colorWhite,
        unselectedLabelColor: colorGrey,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 14),
        tabs: [
          Tab(text: 'Analisis'),
          Tab(text: 'Rekening'),
        ],
      ),
    );
  }

  // ─── Analisis tab ─────────────────────────────────────────────────────────

  Widget _buildAnalisisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildMonthNav(),
          const SizedBox(height: 12),
          _buildAnalisisSummary(),
          const SizedBox(height: 12),
          _buildExpenseDistribution(),
        ],
      ),
    );
  }

  Widget _buildMonthNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: colorCard,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => controller.prevMonth(),
              icon: const Icon(Icons.chevron_left, color: colorGrey, size: 24),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Obx(() => Text(
                  controller.monthLabel,
                  style: const TextStyle(
                    color: colorWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                )),
            IconButton(
              onPressed: () => controller.nextMonth(),
              icon: const Icon(Icons.chevron_right, color: colorGrey, size: 24),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalisisSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: colorCard,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              'Pengeluaran',
              () => controller.pengeluaran.value,
              colorExpense,
            ),
            Container(
              width: 1,
              height: 40,
              color: colorGrey.withValues(alpha: 0.2),
            ),
            _buildSummaryItem(
              'Pemasukan',
              () => controller.pemasukan.value,
              colorIncome,
            ),
            Container(
              width: 1,
              height: 40,
              color: colorGrey.withValues(alpha: 0.2),
            ),
            _buildSummaryItem(
              'Saldo',
              () => controller.saldo.value,
              colorAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    int Function() getValue,
    Color amountColor,
  ) {
    return Obx(() => Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: colorGrey, fontSize: 11),
            ),
            const SizedBox(height: 5),
            Text(
              CurrencyService.to.formatWithoutSymbol(getValue()),
              style: TextStyle(
                color: amountColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ));
  }

  Widget _buildExpenseDistribution() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorCard,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Obx(() {
          if (controller.expenseByCategory.isEmpty) {
            return Column(
              children: [
                const Text(
                  'Distribusi Pengeluaran',
                  style: TextStyle(
                    color: colorWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                Icon(
                  Icons.pie_chart_outline,
                  size: 52,
                  color: colorGrey.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Belum ada pengeluaran bulan ini',
                  style: TextStyle(color: colorGrey),
                ),
                const SizedBox(height: 16),
              ],
            );
          }

          final total = controller.expenseByCategory
              .fold(0, (sum, item) => sum + (item['amount'] as int));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Distribusi Pengeluaran',
                style: TextStyle(
                  color: colorWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 66,
                        sections: controller.expenseByCategory.map((item) {
                          final val = (item['amount'] as int).toDouble();
                          final color = Color(item['color'] as int);
                          final perc =
                              total == 0 ? 0.0 : (val / total * 100);
                          return PieChartSectionData(
                            color: color,
                            value: val,
                            title: '${perc.toStringAsFixed(0)}%',
                            radius: 22,
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorWhite,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(color: colorGrey, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyService.to.format(total),
                          style: const TextStyle(
                            color: colorWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Category list with progress bars
              ...controller.expenseByCategory.map((item) {
                final amount = item['amount'] as int;
                final pct = total == 0 ? 0.0 : amount / total;
                final color = Color(item['color'] as int);
                final name = item['category'] as String;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: colorWhite,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            '${(pct * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: colorGrey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            CurrencyService.to.formatWithoutSymbol(amount),
                            style: const TextStyle(
                              color: colorWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: colorGrey.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        }),
      ),
    );
  }

  // ─── Rekening tab ─────────────────────────────────────────────────────────

  Widget _buildRekeningTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildNetWorthSummary(),
          const SizedBox(height: 16),
          _buildAccountActionRow(),
          const SizedBox(height: 8),
          _buildAccountList(),
        ],
      ),
    );
  }

  Widget _buildNetWorthSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorCard,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kekayaan Bersih',
                  style: TextStyle(color: colorGrey, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyService.to.formatWithoutSymbol(
                      controller.kekayaanBersih.value),
                  style: const TextStyle(
                    color: colorWhite,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Aset',
                            style: TextStyle(color: colorGrey, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyService.to.formatWithoutSymbol(
                                controller.totalAset.value),
                            style: const TextStyle(
                              color: colorIncome,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: colorGrey.withValues(alpha: 0.2),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Total Liabilitas',
                            style: TextStyle(color: colorGrey, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyService.to.formatWithoutSymbol(
                                controller.totalLiabilitas.value),
                            style: const TextStyle(
                              color: colorExpense,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )),
      ),
    );
  }

  Widget _buildAccountActionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                await Get.toNamed('/add-account');
                controller.loadData();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: colorAccent),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add, color: colorAccent, size: 18),
              label: const Text(
                'Tambah Rekening',
                style: TextStyle(
                  color: colorAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                await Get.toNamed('/account-management');
                controller.loadData();
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorGrey.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.settings_outlined,
                  color: colorGrey.withValues(alpha: 0.7), size: 18),
              label: Text(
                'Kelola Rekening',
                style: TextStyle(
                  color: colorGrey.withValues(alpha: 0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountList() {
    return Obx(() {
      if (controller.accountGroups.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 52,
                color: colorGrey.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'Belum ada rekening',
                style: TextStyle(color: colorGrey),
              ),
            ],
          ),
        );
      }

      return Column(
        children: controller.accountGroups.map((group) {
          final accounts = group['accounts'] as List;
          final groupTotal = group['total'] as int;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      (group['groupName'] as String).toUpperCase(),
                      style: const TextStyle(
                        color: colorGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      CurrencyService.to.formatWithoutSymbol(groupTotal),
                      style: const TextStyle(
                        color: colorGrey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: colorCard,
                child: Column(
                  children: accounts.asMap().entries.map((entry) {
                    final i = entry.key;
                    final acc = entry.value as Map<String, dynamic>;
                    final iconCode = acc['icon_code'] as int? ?? 0xe4fc;
                    final colorVal = acc['color_val'] as int? ?? 0xFFFFCA28;
                    // ignore: non_const_argument_for_const_parameter
                    final iconData = IconData(iconCode, fontFamily: 'MaterialIcons');
                    final color = Color(colorVal);
                    final balance = acc['balance'] as int;

                    return Column(
                      children: [
                        if (i > 0)
                          const Divider(color: colorBackground, height: 1),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(iconData, color: color, size: 20),
                          ),
                          title: Text(
                            acc['name'] as String,
                            style: const TextStyle(
                              color: colorWhite,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                CurrencyService.to.formatWithoutSymbol(balance),
                                style: TextStyle(
                                  color: balance < 0 ? colorExpense : colorWhite,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right,
                                color: colorGrey,
                                size: 18,
                              ),
                            ],
                          ),
                          onTap: () {},
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 4),
            ],
          );
        }).toList(),
      );
    });
  }
}
