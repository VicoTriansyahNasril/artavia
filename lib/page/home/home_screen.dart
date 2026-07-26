import 'package:flutter/material.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:artavia/page/home/home_controller.dart';
import 'package:artavia/page/chart/chart_screen.dart';
import 'package:artavia/page/report/report_screen.dart';
import 'package:artavia/page/profile/profile_screen.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/model/transaction_model.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: colorBackground,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.book_outlined, color: colorWhite),
        onPressed: () => Get.toNamed('/ledger'),
        tooltip: 'Buku Kas',
      ),
      title: const Text('Artavia',
          style: TextStyle(
              color: colorWhite, fontSize: 18, fontWeight: FontWeight.bold)),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: colorWhite),
          onPressed: () => Get.toNamed('/search'),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_month_outlined, color: colorWhite),
          onPressed: () => Get.toNamed('/calendar'),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Obx(() => IndexedStack(
          index: controller.currentIndex.value,
          children: [
            _buildHistoryView(),
            const ChartScreen(),
            const ReportScreen(),
            const ProfileScreen(),
          ],
        ));
  }

  // ─── History tab ─────────────────────────────────────────────────────────

  Widget _buildHistoryView() {
    return Column(
      children: [
        _buildSummaryHeader(),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                  child: CircularProgressIndicator(color: colorAccent));
            }
            if (controller.transactions.isEmpty) {
              return _buildEmptyState();
            }
            return RefreshIndicator(
              onRefresh: controller.loadData,
              color: colorAccent,
              backgroundColor: colorCard,
              child: _buildTransactionList(),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: controller.loadData,
      color: colorAccent,
      backgroundColor: colorCard,
      child: const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 400,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 64, color: colorGrey),
                SizedBox(height: 16),
                Text('Belum ada transaksi bulan ini',
                    style: TextStyle(color: colorWhite, fontSize: 16)),
                SizedBox(height: 8),
                Text('Ketuk + untuk mulai mencatat',
                    style: TextStyle(color: colorGrey, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Summary header ──────────────────────────────────────────────────────

  Widget _buildSummaryHeader() {
    return Container(
      color: colorBackground,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Month nav
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: colorGrey, size: 22),
                onPressed: controller.prevMonth,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Obx(() => Column(
                    children: [
                      Text(controller.currentYear,
                          style: const TextStyle(color: colorGrey, fontSize: 11)),
                      Text(controller.currentMonth,
                          style: const TextStyle(
                              color: colorWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  )),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: colorGrey, size: 22),
                onPressed: controller.nextMonth,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Spacer(),
              // Hide/show balance
              GestureDetector(
                onTap: controller.toggleHideBalance,
                child: Obx(() => Icon(
                      controller.hideBalance.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: colorGrey,
                      size: 18,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 3 stat cards — same card color, single accent line
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: colorCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildStat('Pengeluaran', () => controller.totalPengeluaran.value,
                    colorExpense),
                _buildDivider(),
                _buildStat('Pemasukan', () => controller.totalPemasukan.value,
                    colorIncome),
                _buildDivider(),
                _buildStat('Saldo', () => controller.saldoTotal.value,
                    colorAccent, alignRight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int Function() getValue, Color color,
      {bool alignRight = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment:
            alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: colorGrey, fontSize: 11)),
          const SizedBox(height: 4),
          Obx(() => Text(
                controller.hideBalance.value
                    ? '•••••'
                    : CurrencyService.to.formatWithoutSymbol(getValue()),
                style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 32,
      width: 1,
      color: colorGrey.withOpacity(0.15),
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  // ─── Transaction list ────────────────────────────────────────────────────

  Widget _buildTransactionList() {
    final Map<String, List<TransactionModel>> grouped = {};
    for (var tx in controller.transactions) {
      if (tx.date == null) continue;
      final dateStr = DateFormat('d MMMM EEEE', 'id_ID').format(tx.date!);
      grouped.putIfAbsent(dateStr, () => []).add(tx);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final txList = grouped[dateKey]!;

        final dailyExpense = txList
            .where((t) => t.type == 'pengeluaran')
            .fold(0, (s, t) => s + (t.amount ?? 0).abs());
        final dailyIncome = txList
            .where((t) => t.type == 'pemasukan')
            .fold(0, (s, t) => s + (t.amount ?? 0).abs());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dateKey,
                      style: const TextStyle(
                          color: colorGrey,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                  Row(children: [
                    if (dailyIncome > 0)
                      Text(
                          '+${CurrencyService.to.formatWithoutSymbol(dailyIncome)}',
                          style: const TextStyle(
                              color: colorIncome, fontSize: 11)),
                    if (dailyIncome > 0 && dailyExpense > 0)
                      const SizedBox(width: 8),
                    if (dailyExpense > 0)
                      Text(
                          '-${CurrencyService.to.formatWithoutSymbol(dailyExpense)}',
                          style: const TextStyle(
                              color: colorExpense, fontSize: 11)),
                  ]),
                ],
              ),
            ),
            Container(
              color: colorCard,
              child: Column(
                children: txList.asMap().entries.map((e) {
                  final i = e.key;
                  final tx = e.value;
                  return Column(
                    children: [
                      if (i > 0)
                        const Divider(
                            color: colorBackground,
                            height: 1,
                            indent: 64),
                      _buildTransactionItem(tx),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionItem(TransactionModel tx) {
    final isExpense = tx.type == 'pengeluaran';
    final isTransfer = tx.type == 'transfer';

    // Icon per category — SAME color (colorAccent for income, colorExpense for expense)
    final iconColor =
        isTransfer ? colorGrey : isExpense ? colorExpense : colorIncome;
    final iconBg = iconColor.withOpacity(0.1);

    IconData iconData;
    final cat = tx.categoryName?.toLowerCase() ?? '';
    if (isTransfer) {
      iconData = Icons.swap_horiz;
    } else if (cat.contains('makan') || cat.contains('minum')) {
      iconData = Icons.restaurant_outlined;
    } else if (cat.contains('belanja')) {
      iconData = Icons.shopping_bag_outlined;
    } else if (cat.contains('transport') || cat.contains('bensin')) {
      iconData = Icons.directions_car_outlined;
    } else if (cat.contains('gaji') || cat.contains('bonus')) {
      iconData = Icons.attach_money;
    } else if (cat.contains('kesehatan')) {
      iconData = Icons.medical_services_outlined;
    } else if (cat.contains('tagihan') || cat.contains('listrik')) {
      iconData = Icons.receipt_outlined;
    } else {
      iconData = isExpense ? Icons.arrow_upward : Icons.arrow_downward;
    }

    final displayAmount = (tx.amount ?? 0).abs();
    final amountColor =
        isTransfer ? colorGrey : isExpense ? colorExpense : colorIncome;
    final prefix = isTransfer ? '' : isExpense ? '-' : '+';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () => Get.toNamed('/transaction-detail', arguments: {
        'id': tx.id,
        'type': tx.type,
        'amount': displayAmount,
        'category': tx.categoryName,
        'note': tx.note,
        'account': tx.account ?? 'CASH',
        'date': tx.date,
      }),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: iconBg,
        child: Icon(iconData, color: iconColor, size: 18),
      ),
      title: Text(
        tx.note?.isNotEmpty == true ? tx.note! : (tx.categoryName ?? '-'),
        style: const TextStyle(
            color: colorWhite, fontSize: 14, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        tx.categoryName ?? '',
        style: const TextStyle(color: colorGrey, fontSize: 11),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$prefix${CurrencyService.to.formatWithoutSymbol(displayAmount)}',
            style: TextStyle(
                color: amountColor,
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
          Text(tx.account ?? '',
              style: const TextStyle(color: colorGrey, fontSize: 10)),
        ],
      ),
    );
  }

  // ─── FAB — speed dial ────────────────────────────────────────────────────

  Widget _buildFAB() {
    return Obx(() {
      final isOpen = controller.isFabOpen.value;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isOpen) ...[
            _fabOption('Transfer', Icons.swap_horiz, () {
              controller.isFabOpen.value = false;
              Get.toNamed('/transfer');
            }),
            const SizedBox(height: 10),
            _fabOption('Pemasukan', Icons.add, () {
              controller.isFabOpen.value = false;
              Get.toNamed('/add-transaction',
                  arguments: {'initialTab': 'Pemasukan'});
            }),
            const SizedBox(height: 10),
            _fabOption('Pengeluaran', Icons.remove, () {
              controller.isFabOpen.value = false;
              Get.toNamed('/add-transaction',
                  arguments: {'initialTab': 'Pengeluaran'});
            }),
            const SizedBox(height: 14),
          ],
          FloatingActionButton(
            onPressed: () {
              if (controller.currentIndex.value == 0) {
                controller.isFabOpen.value = !isOpen;
              } else {
                controller.isFabOpen.value = false;
                Get.toNamed('/add-transaction');
              }
            },
            backgroundColor: colorAccent,
            elevation: 2,
            shape: const CircleBorder(),
            child: Icon(
              isOpen ? Icons.close : Icons.add,
              color: colorBlack,
              size: 28,
            ),
          ),
        ],
      );
    });
  }

  Widget _fabOption(String label, IconData icon, VoidCallback onTap) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: colorCard,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label,
              style: const TextStyle(color: colorWhite, fontSize: 12)),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: colorCard,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorWhite, size: 18),
          ),
        ),
      ],
    );
  }

  // ─── Bottom nav ──────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: colorCard,
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Riwayat', 0),
          _navItem(Icons.pie_chart_outline, Icons.pie_chart, 'Grafik', 1),
          const SizedBox(width: 40),
          _navItem(Icons.bar_chart_outlined, Icons.bar_chart, 'Laporan', 2),
          _navItem(Icons.person_outline, Icons.person, 'Saya', 3),
        ],
      ),
    );
  }

  Widget _navItem(
      IconData unsel, IconData sel, String label, int index) {
    return Obx(() {
      final active = controller.currentIndex.value == index;
      return InkWell(
        onTap: () {
          controller.isFabOpen.value = false;
          controller.changePage(index);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? sel : unsel,
                  color: active ? colorAccent : colorGrey, size: 22),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      color: active ? colorAccent : colorGrey,
                      fontSize: 10,
                      fontWeight: active
                          ? FontWeight.bold
                          : FontWeight.normal)),
            ],
          ),
        ),
      );
    });
  }
}
