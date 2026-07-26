import 'package:flutter/material.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:get/get.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/page/budget/budget_controller.dart';

class BudgetScreen extends StatelessWidget {
  final BudgetController controller = Get.put(BudgetController());

  BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        backgroundColor: colorBackground,
        title: const Text('Anggaran Bulanan',
            style: TextStyle(color: colorWhite, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: colorWhite),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMonthNav(),
              const SizedBox(height: 16),
              _buildTotalBudgetCard(context),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Anggaran Kategori',
                      style: TextStyle(
                          color: colorWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () =>
                        controller.showAddBudgetDialog(context),
                    icon: const Icon(Icons.add, color: colorAccent, size: 18),
                    label: const Text('Tambah',
                        style: TextStyle(color: colorAccent)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (controller.budgetItems.isEmpty) _buildEmptyState(),
              ...controller.budgetItems.map(
                  (item) => _buildCategoryBudgetCard(context, item)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMonthNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              )),
          GestureDetector(
            onTap: () => controller.nextMonth(),
            child: const Icon(Icons.chevron_right, color: colorGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.pie_chart_outline,
                size: 48, color: colorGrey.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('Belum ada anggaran bulan ini',
                style: TextStyle(color: colorGrey)),
            const SizedBox(height: 8),
            const Text('Ketuk "Tambah" untuk membuat anggaran kategori',
                style: TextStyle(color: colorGrey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBudgetCard(BuildContext context) {
    return Obx(() {
      final used = controller.totalUsed;
      final total = controller.totalBudget;
      final sisa = total - used;
      final percent = total > 0 ? used / total : 0.0;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorGrey.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total Anggaran',
                style: TextStyle(color: colorGrey, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              total == 0
                  ? 'Belum ada anggaran'
                  : CurrencyService.to.format(total),
              style: const TextStyle(
                  color: colorWhite,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
            if (total > 0) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percent.clamp(0.0, 1.0),
                  minHeight: 12,
                  backgroundColor: colorBackground,
                  color:
                      percent > 0.8 ? colorExpense : colorIncome,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Terpakai',
                          style:
                              TextStyle(color: colorGrey, fontSize: 12)),
                      Text(
                        CurrencyService.to.format(used),
                        style: const TextStyle(
                            color: colorWhite,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Sisa',
                          style:
                              TextStyle(color: colorGrey, fontSize: 12)),
                      Text(
                        CurrencyService.to.format(sisa),
                        style: TextStyle(
                            color: sisa < 0 ? colorExpense : colorIncome,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildCategoryBudgetCard(
      BuildContext context, Map<String, dynamic> item) {
    final int budget = item['budget_amount'] as int;
    final int used = item['used'] as int;
    final Color color = Color(item['color'] as int);
    final IconData icon = item['icon'] as IconData;
    final double percent = budget > 0 ? used / budget : 0.0;
    final isOverBudget = used > budget;

    return Dismissible(
      key: Key('budget_${item['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorExpense.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: colorExpense),
      ),
      confirmDismiss: (_) async {
        bool confirmed = false;
        await Get.defaultDialog(
          backgroundColor: colorCard,
          title: 'Hapus Anggaran',
          titleStyle: const TextStyle(color: colorWhite),
          middleText: 'Hapus anggaran ${item['category']}?',
          middleTextStyle: const TextStyle(color: colorGrey),
          confirm: ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: colorExpense),
            onPressed: () {
              confirmed = true;
              Get.back();
            },
            child: const Text('Hapus',
                style: TextStyle(color: colorWhite)),
          ),
          cancel: TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal',
                style: TextStyle(color: colorGrey)),
          ),
        );
        return confirmed;
      },
      onDismissed: (_) => controller.deleteBudget(item['id'] as int),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorCard,
          borderRadius: BorderRadius.circular(16),
          border: isOverBudget
              ? Border.all(color: colorExpense.withOpacity(0.4))
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  radius: 20,
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['category'] as String,
                          style: const TextStyle(
                              color: colorWhite,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        '${CurrencyService.to.format(used)} / ${CurrencyService.to.format(budget)}',
                        style: const TextStyle(
                            color: colorGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.edit_outlined,
                          color: colorGrey, size: 18),
                      onPressed: () =>
                          controller.showEditBudgetDialog(context, item),
                    ),
                    if (isOverBudget)
                      const Text('Melewati batas!',
                          style: TextStyle(
                              color: colorExpense, fontSize: 10)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: colorBackground,
                color: percent > 1.0
                    ? colorExpense
                    : percent > 0.8
                        ? Colors.orange
                        : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
