import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/date_format.dart';
import 'package:artavia/page/home/home_controller.dart';
import 'package:artavia/page/chart/chart_screen.dart';
import 'package:artavia/page/report/report_screen.dart';
import 'package:artavia/page/profile/profile_screen.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/components/bouncy_button.dart';
import 'package:artavia/widgets/transaction/transaction_item.dart';
import 'package:artavia/model/transaction_model.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) controller.showTutorialIfNoAccount();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artavia',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Cari',
            onPressed: () => Get.toNamed(searchRoute),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Kalender',
            onPressed: () => Get.toNamed(calendarRoute),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() => IndexedStack(
            index: controller.currentIndex.value,
            children: const [
              HistoryView(),
              ChartScreen(),
              ReportScreen(),
              ProfileScreen(),
            ],
          )),
      bottomNavigationBar: const _BottomNav(),
      floatingActionButton: BouncyButton(
        onPressed: () => Get.toNamed(addTransactionRoute),
        child: Container(
          width: 56,
          height: 56,
          decoration:
              const BoxDecoration(color: colorAccent, shape: BoxShape.circle),
          child: const Icon(Icons.add_rounded, color: colorOnAccent, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _BottomNav extends GetView<HomeController> {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: colorCard,
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      height: 64,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _item(Icons.receipt_long_outlined, Icons.receipt_long, 'Riwayat', 0),
          _item(Icons.pie_chart_outline, Icons.pie_chart, 'Grafik', 1),
          const SizedBox(width: 48),
          _item(Icons.account_balance_wallet_outlined,
              Icons.account_balance_wallet, 'Aset', 2),
          _item(Icons.person_outline, Icons.person, 'Saya', 3,
              key: controller.keyBottomNavProfile),
        ],
      ),
    );
  }

  Widget _item(IconData off, IconData on, String label, int index, {Key? key}) {
    return Obx(() {
      final active = controller.currentIndex.value == index;
      final color = active ? colorAccent : colorGrey;
      return BouncyButton(
        key: key,
        onPressed: () => controller.changePage(index),
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? on : off, color: color, size: 22),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.normal)),
            ],
          ),
        ),
      );
    });
  }
}

class HistoryView extends GetView<HomeController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.loadData,
      backgroundColor: colorCard,
      child: Obx(() {
        final grouped = controller.groupedTransactions;
        final keys = grouped.keys.toList();
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: keys.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return const _HistoryHeader();
            final key = keys[index - 1];
            return _DayGroup(title: key, items: grouped[key]!);
          },
        );
      }),
    );
  }
}

/// Period picker, monthly totals, budget card and loading/empty states.
class _HistoryHeader extends GetView<HomeController> {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final empty = controller.transactions.isEmpty;
      return Column(
        children: [
          const _SummaryCard(),
          if (controller.budget.value.total > 0) const _BudgetCard(),
          if (controller.isLoading.value && empty)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (empty)
            const _EmptyState(),
        ],
      );
    });
  }
}

class _SummaryCard extends GetView<HomeController> {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => showPeriodPicker(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Obx(() => Text(controller.period.label,
                        style: const TextStyle(
                            color: colorText,
                            fontSize: 16,
                            fontWeight: FontWeight.w600))),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: colorGrey, size: 20),
                  ]),
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Sembunyikan saldo',
                onPressed: controller.toggleHideBalance,
                icon: Obx(() => Icon(
                      controller.hideBalance.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: colorGrey,
                      size: 18,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _stat('Pengeluaran', () => controller.totalPengeluaran.value,
                  colorExpense),
              _stat('Pemasukan', () => controller.totalPemasukan.value,
                  colorIncome),
              _stat('Saldo', () => controller.saldoTotal.value, colorText),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int Function() value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: colorGrey, fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Obx(() => Text(
                  controller.hideBalance.value
                      ? '••••••'
                      : CurrencyService.to.formatWithoutSymbol(value()),
                  style: TextStyle(
                      color: color, fontSize: 16, fontWeight: FontWeight.w600),
                )),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends GetView<HomeController> {
  const _BudgetCard();

  @override
  Widget build(BuildContext context) {
    final b = controller.budget.value;
    final tone = b.overCount > 0
        ? colorExpense
        : b.ratio >= 0.8
            ? colorWarning
            : colorAccent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: colorCard,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Get.toNamed(budgetRoute),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('Anggaran',
                      style: TextStyle(color: colorGrey, fontSize: 12)),
                  const Spacer(),
                  Text(
                    '${CurrencyService.to.formatWithoutSymbol(b.used)} / '
                    '${CurrencyService.to.formatWithoutSymbol(b.total)}',
                    style: const TextStyle(color: colorText, fontSize: 12),
                  ),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: b.ratio.clamp(0, 1).toDouble(),
                    minHeight: 6,
                    backgroundColor: colorSurface,
                    valueColor: AlwaysStoppedAnimation(tone),
                  ),
                ),
                if (b.overCount > 0) ...[
                  const SizedBox(height: 8),
                  Text('${b.overCount} kategori melewati batas',
                      style:
                          const TextStyle(color: colorExpense, fontSize: 12)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: colorGrey),
          SizedBox(height: 16),
          Text('Belum ada transaksi pada periode ini',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: colorText, fontSize: 15, fontWeight: FontWeight.w500)),
          SizedBox(height: 6),
          Text('Ketuk + untuk mulai mencatat',
              style: TextStyle(color: colorGrey, fontSize: 13)),
        ],
      ),
    );
  }
}

class _DayGroup extends StatelessWidget {
  final String title;
  final List<TransactionModel> items;

  const _DayGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final expense = items
        .where((t) => t.type == 'pengeluaran')
        .fold<int>(0, (s, t) => s + (t.amount ?? 0).abs());
    final income = items
        .where((t) => t.type == 'pemasukan')
        .fold<int>(0, (s, t) => s + (t.amount ?? 0).abs());
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Row(
              children: [
                Text(title,
                    style: const TextStyle(color: colorGrey, fontSize: 12)),
                const Spacer(),
                if (income > 0)
                  Text('+${CurrencyService.to.formatWithoutSymbol(income)}',
                      style: const TextStyle(color: colorIncome, fontSize: 11)),
                if (income > 0 && expense > 0) const SizedBox(width: 8),
                if (expense > 0)
                  Text('-${CurrencyService.to.formatWithoutSymbol(expense)}',
                      style:
                          const TextStyle(color: colorExpense, fontSize: 11)),
              ],
            ),
          ),
          Material(
            color: colorCard,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(indent: 68),
                  TransactionItem(tx: items[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet to pick the shared active month (FR-021, FR-022).
void showPeriodPicker() {
  final service = PeriodService.to;
  final year = service.active.value.year.obs;
  Get.bottomSheet(
    SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => year.value--,
                ),
                Obx(() => Text('${year.value}',
                    style: const TextStyle(
                        color: colorText,
                        fontSize: 17,
                        fontWeight: FontWeight.w600))),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => year.value++,
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: List.generate(12, (i) {
                return Obx(() {
                  final active = service.active.value;
                  final selected =
                      active.year == year.value && active.month == i + 1;
                  return Material(
                    color: selected ? colorAccent : colorSurface,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        service.select(year.value, i + 1);
                        Get.back();
                      },
                      child: Center(
                        child: Text(
                          IdNames.monthShort(i + 1),
                          style: TextStyle(
                            color: selected ? colorOnAccent : colorText,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                });
              }),
            ),
          ],
        ),
      ),
    ),
  );
}
