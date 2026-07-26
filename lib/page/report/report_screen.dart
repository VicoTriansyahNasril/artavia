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
        labelColor: colorWhite,
        unselectedLabelColor: colorGrey,
        labelStyle: TextStyle(fontWeight: FontWeight.bold),
        tabs: [
          Tab(text: 'Analisis'),
          Tab(text: 'Rekening'),
        ],
      ),
    );
  }

  Widget _buildAnalisisTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildMonthNav(),
          const SizedBox(height: 16),
          _buildAnalisisSummary(),
          const SizedBox(height: 16),
          _buildBudgetChart(),
        ],
      ),
    );
  }

  Widget _buildMonthNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colorCard,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => controller.prevMonth(),
              child: const Icon(Icons.chevron_left, color: colorGrey),
            ),
            Obx(() => Text(
                  controller.monthLabel,
                  style: const TextStyle(
                      color: colorWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                )),
            GestureDetector(
              onTap: () => controller.nextMonth(),
              child: const Icon(Icons.chevron_right, color: colorGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalisisSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Pengeluaran',
              () => controller.pengeluaran.value, colorExpense),
          Container(width: 1, height: 40, color: colorGrey.withOpacity(0.2)),
          _buildSummaryItem(
              'Pemasukan', () => controller.pemasukan.value, colorIncome),
          Container(width: 1, height: 40, color: colorGrey.withOpacity(0.2)),
          _buildSummaryItem('Saldo', () => controller.saldo.value, colorWhite),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String title, int Function() getValue, Color amountColor) {
    return Obx(() => Column(
          children: [
            Text(title,
                style: const TextStyle(color: colorGrey, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              CurrencyService.to.formatWithoutSymbol(getValue()),
              style: TextStyle(
                  color: amountColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ));
  }

  Widget _buildBudgetChart() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Obx(() {
        if (controller.expenseByCategory.isEmpty) {
          return Column(
            children: [
              const Text('Distribusi Pengeluaran',
                  style: TextStyle(
                      color: colorWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 32),
              Icon(Icons.pie_chart_outline,
                  size: 48, color: colorGrey.withOpacity(0.4)),
              const SizedBox(height: 12),
              const Text('Belum ada pengeluaran bulan ini',
                  style: TextStyle(color: colorGrey)),
              const SizedBox(height: 16),
            ],
          );
        }

        final total = controller.expenseByCategory
            .fold(0, (sum, item) => sum + (item['amount'] as int));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Distribusi Pengeluaran',
                style: TextStyle(
                    color: colorWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 32),
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 70,
                      sections: controller.expenseByCategory.map((item) {
                        final val = (item['amount'] as int).toDouble();
                        final color = Color(item['color'] as int);
                        final perc = total == 0 ? 0.0 : (val / total * 100);
                        return PieChartSectionData(
                          color: color,
                          value: val,
                          title:
                              '${perc.toStringAsFixed(0)}%',
                          radius: 20,
                          titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorWhite),
                        );
                      }).toList(),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total',
                          style:
                              TextStyle(color: colorGrey, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyService.to.format(total),
                        style: const TextStyle(
                            color: colorWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...controller.expenseByCategory.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                          color: Color(item['color'] as int),
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item['category'] as String,
                          style: const TextStyle(
                              color: colorWhite, fontSize: 13)),
                    ),
                    Text(
                      CurrencyService.to.format(item['amount']),
                      style: const TextStyle(
                          color: colorWhite, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      }),
    );
  }

  Widget _buildRekeningTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildNetWorthSummary(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Get.toNamed('/add-account');
                  controller.loadData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorCard,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: colorAccent, width: 1),
                  ),
                ),
                icon: const Icon(Icons.add, color: colorAccent, size: 20),
                label: const Text('Tambah Rekening',
                    style: TextStyle(color: colorAccent, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildAccountList(),
        ],
      ),
    );
  }

  Widget _buildNetWorthSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Obx(() => Column(
            children: [
              const Text('Kekayaan Bersih',
                  style: TextStyle(color: colorGrey, fontSize: 12)),
              const SizedBox(height: 8),
              Text(
                CurrencyService.to
                    .formatWithoutSymbol(controller.kekayaanBersih.value),
                style: const TextStyle(
                    color: colorWhite,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Total Aset',
                          style:
                              TextStyle(color: colorGrey, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyService.to.formatWithoutSymbol(
                            controller.totalAset.value),
                        style: const TextStyle(
                            color: colorIncome,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                      width: 1,
                      height: 36,
                      color: colorGrey.withOpacity(0.2)),
                  Column(
                    children: [
                      const Text('Total Liabilitas',
                          style:
                              TextStyle(color: colorGrey, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyService.to.formatWithoutSymbol(
                            controller.totalLiabilitas.value),
                        style: const TextStyle(
                            color: colorExpense,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          )),
    );
  }

  Widget _buildAccountList() {
    return Obx(() {
      if (controller.accountGroups.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 48, color: colorGrey.withOpacity(0.4)),
              const SizedBox(height: 12),
              const Text('Belum ada rekening',
                  style: TextStyle(color: colorGrey)),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(group['groupName'] as String,
                        style: const TextStyle(
                            color: colorGrey,
                            fontSize: 11,
                            letterSpacing: 0.5)),
                    Text(
                      CurrencyService.to.formatWithoutSymbol(groupTotal),
                      style: const TextStyle(
                          color: colorGrey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                color: colorCard,
                child: Column(
                  children: accounts.asMap().entries.map((entry) {
                    final i = entry.key;
                    final acc = entry.value as Map<String, dynamic>;
                    final iconCode = acc['icon_code'] as int? ?? 0xe4fc;
                    final colorVal = acc['color_val'] as int? ?? 0xFFFFCA28;
                    final iconData =
                        IconData(iconCode, fontFamily: 'MaterialIcons');
                    final color = Color(colorVal);
                    final balance = acc['balance'] as int;

                    return Column(
                      children: [
                        if (i > 0)
                          const Divider(color: colorBackground, height: 1),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.2),
                            radius: 20,
                            child:
                                Icon(iconData, color: color, size: 20),
                          ),
                          title: Text(acc['name'] as String,
                              style: const TextStyle(
                                  color: colorWhite,
                                  fontWeight: FontWeight.w600)),
                          trailing: Text(
                            CurrencyService.to.formatWithoutSymbol(balance),
                            style: TextStyle(
                              color: balance < 0 ? colorExpense : colorWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      );
    });
  }
}
