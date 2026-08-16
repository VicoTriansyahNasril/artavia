import 'package:flutter/material.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:get/get.dart';
import 'package:artavia/page/home/home_controller.dart';
import 'package:artavia/page/chart/chart_screen.dart';
import 'package:artavia/page/report/report_screen.dart';
import 'package:artavia/page/profile/profile_screen.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/components/bouncy_button.dart';
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
          children: const [
            HistoryView(),
            ChartScreen(),
            ReportScreen(),
            ProfileScreen(),
          ],
        ));
  }

    // ─── FAB — speed dial ────────────────────────────────────────────────────

  Widget _buildFAB() {
    return BouncyButton(
      onPressed: () => Get.toNamed('/add-transaction'),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: colorAccent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorAccent.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: const Icon(Icons.add, color: colorOnAccent, size: 28),
      ),
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
      return BouncyButton(
        onPressed: () {
          controller.isFabOpen.value = false;
          controller.changePage(index);
        },
        child: Container(
          color: Colors.transparent, // Ensure full hit area
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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


class HistoryView extends GetView<HomeController> {
  const HistoryView({super.key});

// ─── History tab ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Month Year Picker
          GestureDetector(
            onTap: () => _showMonthPicker(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                      controller.currentYear,
                      style: const TextStyle(color: colorGrey, fontSize: 11),
                    )),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Obx(() => Text(
                          controller.currentMonth,
                          style: const TextStyle(
                            color: colorWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                    const Icon(Icons.keyboard_arrow_down,
                        color: colorWhite, size: 16),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Stats
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildStat(
                    'Pengeluaran',
                    () => controller.totalPengeluaran.value,
                    colorWhite,
                    align: CrossAxisAlignment.start,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: _buildStat(
                    'Pemasukan',
                    () => controller.totalPemasukan.value,
                    colorWhite,
                    align: CrossAxisAlignment.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: _buildStat(
                    'Saldo',
                    () => controller.saldoTotal.value,
                    colorWhite,
                    align: CrossAxisAlignment.end,
                    isTotal: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMonthPicker() {
    // Temporary year state for the picker
    final RxInt selectedYear = controller.currentDate.value.year.obs;
    final List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    Get.bottomSheet(
      Material(
        color: colorCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: colorWhite),
                  onPressed: () => selectedYear.value--,
                ),
                Obx(() => Text(
                      '${selectedYear.value}',
                      style: const TextStyle(
                        color: colorWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: colorWhite),
                  onPressed: () => selectedYear.value++,
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                return Obx(() {
                  final isCurrentMonth = controller.currentDate.value.year == selectedYear.value && 
                                         controller.currentDate.value.month == index + 1;
                  return InkWell(
                    onTap: () {
                      controller.currentDate.value = DateTime(selectedYear.value, index + 1);
                      controller.loadData();
                      Get.back();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCurrentMonth ? colorAccent : colorBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        months[index],
                        style: TextStyle(
                          color: isCurrentMonth ? colorOnAccent : colorWhite,
                          fontWeight: isCurrentMonth ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                });
              },
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStat(
    String label,
    int Function() getValue,
    Color color, {
    CrossAxisAlignment align = CrossAxisAlignment.start,
    bool isTotal = false,
  }) {
    return GestureDetector(
      onTap: controller.toggleHideBalance,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(color: colorGrey, fontSize: 12),
              ),
              if (isTotal) ...[
                const SizedBox(width: 4),
                Obx(() => Icon(
                      controller.hideBalance.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: colorGrey,
                      size: 14,
                    )),
              ],
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: align == CrossAxisAlignment.end
                ? Alignment.centerRight
                : align == CrossAxisAlignment.center
                    ? Alignment.center
                    : Alignment.centerLeft,
            child: Obx(() => Text(
                  controller.hideBalance.value
                      ? '••••••'
                      : CurrencyService.to.formatWithoutSymbol(getValue()),
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                )),
          ),
        ],
      ),
    );
  }

  // ─── Transaction list ────────────────────────────────────────────────────

  Widget _buildTransactionList() {
    final grouped = controller.groupedTransactions;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: grouped.length,
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


}
