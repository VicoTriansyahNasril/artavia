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
      title: const Text(
        'Artavia',
        style: TextStyle(
          color: colorWhite,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
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
                Icon(Icons.receipt_long_outlined, size: 56, color: colorGrey),
                SizedBox(height: 16),
                Text(
                  'Belum ada transaksi bulan ini',
                  style: TextStyle(
                    color: colorWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Ketuk + untuk mulai mencatat',
                  style: TextStyle(color: colorGrey, fontSize: 13),
                ),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: colorGrey, size: 24),
                    onPressed: controller.prevMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  Obx(() => Column(
                        children: [
                          Text(
                            controller.currentYear,
                            style: const TextStyle(color: colorGrey, fontSize: 11),
                          ),
                          Text(
                            controller.currentMonth,
                            style: const TextStyle(
                              color: colorWhite,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: colorGrey, size: 24),
                    onPressed: controller.nextMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                child: GestureDetector(
                  onTap: controller.toggleHideBalance,
                  child: Obx(() => Icon(
                        controller.hideBalance.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: colorGrey,
                        size: 22,
                      )),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 3 stat cards in a single row card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: colorCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildStat(
                  'Pengeluaran',
                  () => controller.totalPengeluaran.value,
                  colorExpense,
                ),
                _buildDivider(),
                _buildStat(
                  'Pemasukan',
                  () => controller.totalPemasukan.value,
                  colorIncome,
                ),
                _buildDivider(),
                _buildStat(
                  'Saldo',
                  () => controller.saldoTotal.value,
                  colorAccent,
                  alignRight: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    String label,
    int Function() getValue,
    Color color, {
    bool alignRight = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment:
            alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: colorGrey, fontSize: 11),
          ),
          const SizedBox(height: 5),
          Obx(() => Text(
                controller.hideBalance.value
                    ? '•••••'
                    : CurrencyService.to.formatWithoutSymbol(getValue()),
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 36,
      width: 1,
      color: colorGrey.withValues(alpha: 0.15),
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  // ─── Transaction list ────────────────────────────────────────────────────

  Widget _buildTransactionList() {
    final Map<String, List<TransactionModel>> grouped = {};
    for (var tx in controller.transactions) {
      if (tx.date == null) continue;
      final dateStr = DateFormat('d MMM · EEEE', 'id_ID').format(tx.date!);
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
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
              child: Row(
                children: [
                  // Accent line
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: colorAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateKey,
                    style: const TextStyle(
                      color: colorGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (dailyIncome > 0)
                    Text(
                      '+${CurrencyService.to.formatWithoutSymbol(dailyIncome)}',
                      style: const TextStyle(
                        color: colorIncome,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (dailyIncome > 0 && dailyExpense > 0)
                    const SizedBox(width: 8),
                  if (dailyExpense > 0)
                    Text(
                      '-${CurrencyService.to.formatWithoutSymbol(dailyExpense)}',
                      style: const TextStyle(
                        color: colorExpense,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            Material(
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
                          indent: 64,
                        ),
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

    // Use category color from DB if available, else fallback to type color
    final Color iconColor;

    int? iconCode;
    String? iconPath;

    if (isTransfer) {
      iconColor = colorGrey;
      iconCode = Icons.swap_horiz.codePoint;
    } else if (tx.categoryColorVal != null && tx.categoryColorVal != 0) {
      iconColor = Color(tx.categoryColorVal!);
      iconCode = tx.categoryIconCode;
      iconPath = tx.categoryIconPath;
      if (iconCode == null && iconPath == null) {
        iconCode = isExpense ? Icons.arrow_upward.codePoint : Icons.arrow_downward.codePoint;
      }
    } else {
      iconColor = isExpense ? colorExpense : colorIncome;
      iconCode = isExpense ? Icons.arrow_upward.codePoint : Icons.arrow_downward.codePoint;
    }

    final iconBg = iconColor.withValues(alpha: 0.15);
    final displayAmount = (tx.amount ?? 0).abs();
    final amountColor =
        isTransfer ? colorGrey : isExpense ? colorExpense : colorIncome;
    final prefix = isTransfer ? '' : isExpense ? '-' : '+';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      onTap: () => Get.toNamed('/transaction-detail', arguments: {
        'id': tx.id,
        'type': tx.type,
        'amount': displayAmount,
        'category': tx.categoryName,
        'note': tx.note,
        'account': tx.accountName ?? 'CASH',
        'account_id': tx.accountId,
        'destination_account': tx.destinationAccountName,
        'destination_account_id': tx.destinationAccountId,
        'date': tx.date,
        'icon_code': iconCode,
        'icon_path': iconPath,
        'color_val': iconColor.toARGB32(),
      }),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: iconBg,
        child: CategoryIcon(
          iconCode: iconCode,
          iconPath: iconPath,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        tx.note?.isNotEmpty == true ? tx.note! : (tx.categoryName ?? '-'),
        style: const TextStyle(
          color: colorWhite,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          isTransfer
              ? '${tx.accountName ?? ''} → ${tx.destinationAccountName ?? ''}'
              : (tx.categoryName ?? ''),
          style: const TextStyle(color: colorGrey, fontSize: 11),
        ),
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
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tx.accountName ?? '',
            style: const TextStyle(color: colorGrey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ─── FAB — speed dial ────────────────────────────────────────────────────

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => Get.toNamed('/add-transaction'),
      backgroundColor: colorAccent,
      elevation: 2,
      shape: const CircleBorder(),
      child: const Icon(Icons.add, color: colorBlack, size: 28),
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

  Widget _navItem(IconData unsel, IconData sel, String label, int index) {
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
              Icon(
                active ? sel : unsel,
                color: active ? colorAccent : colorGrey,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: active ? colorAccent : colorGrey,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
