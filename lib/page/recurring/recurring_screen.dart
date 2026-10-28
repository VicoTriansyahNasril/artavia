import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/models/recurring_rule.dart';
import 'package:artavia/core/services/recurring_service.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/date_format.dart';
import 'package:artavia/page/recurring/recurring_controller.dart';
import 'package:artavia/widgets/commons/common.dart';

class RecurringScreen extends GetView<RecurringController> {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi Berulang')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => controller.openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.rules.isEmpty) return const _EmptyState();
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: controller.rules.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _RuleTile(rule: controller.rules[i]),
        );
      }),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.repeat_rounded, size: 48, color: colorGrey),
            SizedBox(height: 16),
            Text('Belum ada transaksi berulang',
                style: TextStyle(
                    color: colorText,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            SizedBox(height: 6),
            Text(
              'Gaji, sewa, atau langganan bisa dicatat otomatis setiap periode.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorGrey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleTile extends GetView<RecurringController> {
  final RecurringRule rule;

  const _RuleTile({required this.rule});

  @override
  Widget build(BuildContext context) {
    final color = rule.categoryColorVal != null
        ? Color(rule.categoryColorVal!)
        : colorGrey;
    final isExpense = rule.type == 'pengeluaran';
    final next = nextOccurrence(rule);
    return Material(
      color: colorCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => controller.openForm(rule),
        onLongPress: () => controller.delete(rule),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.15),
                child: CategoryIcon(
                  iconCode: rule.categoryIconCode,
                  iconPath: rule.categoryIconPath,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.note.isNotEmpty
                          ? rule.note
                          : (rule.categoryName ?? '-'),
                      style: const TextStyle(
                          color: colorText, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${rule.frequency.label} · ${rule.accountName ?? '-'}'
                      '${rule.isActive ? ' · berikutnya ${IdNames.shortDate(next)}' : ' · dijeda'}',
                      style: const TextStyle(color: colorGrey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isExpense ? '-' : '+'}${CurrencyService.to.format(rule.amount)}',
                      style: TextStyle(
                        color: isExpense ? colorExpense : colorIncome,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: rule.isActive,
                onChanged: (v) => controller.toggleActive(rule, v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
