import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/models/recurring_rule.dart';
import 'package:artavia/core/services/recurring_service.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/date_format.dart';
import 'package:artavia/page/recurring/recurring_controller.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// Transaksi berulang: rules with next date, pause switch, tap to edit.
class RecurringScreen extends GetView<RecurringController> {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      leading: ScaffoldLeading.back,
      title: 'Transaksi berulang',
      actions: [
        KIconButton(
          icon: LucideIcons.plus,
          semanticLabel: 'Tambah transaksi berulang',
          onPressed: () => controller.openForm(),
        ),
      ],
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.rules.isEmpty) {
          return EmptyState(
            icon: LucideIcons.repeat,
            title: 'Belum ada transaksi berulang',
            body: 'Gaji, sewa, atau langganan bisa dicatat otomatis setiap '
                'periode.',
            action: KButton.tonal(
              label: 'Tambah',
              icon: LucideIcons.plus,
              onPressed: () => controller.openForm(),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            ListGroup(
              children: [
                for (final r in controller.rules) _RuleRow(rule: r),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
              child: Text(
                  'Transaksi jatuh tempo dicatat otomatis saat aplikasi '
                  'dibuka. Ketuk untuk mengubah atau menghapus.',
                  style: AppText.caption.muted),
            ),
          ],
        );
      }),
    );
  }
}

class _RuleRow extends GetView<RecurringController> {
  final RecurringRule rule;
  const _RuleRow({required this.rule});

  @override
  Widget build(BuildContext context) {
    final isExpense = rule.type == 'pengeluaran';
    final title = rule.note.isNotEmpty
        ? rule.note
        : (rule.categoryName ?? 'Tanpa kategori');
    final amount = CurrencyService.to
        .money(isExpense ? -rule.amount : rule.amount, signed: true);
    return NavRow(
      leading: CategoryIcon.round(
        iconKey: rule.categoryIconKey,
        iconPath: rule.categoryIconPath,
        iconCode: rule.categoryIconCode,
        color: themedColor(rule.categoryColorVal),
      ),
      title: title,
      subtitle: [
        amount,
        rule.frequency.label,
        rule.accountName ?? '—',
        rule.isActive
            ? 'berikutnya ${IdNames.shortDate(nextOccurrence(rule))}'
            : 'dijeda',
      ].join(' · '),
      showChevron: false,
      trailing: KSwitch(
        value: rule.isActive,
        semanticLabel: 'Aktifkan $title',
        onChanged: (v) => controller.toggleActive(rule, v),
      ),
      onTap: () => controller.openForm(rule),
    );
  }
}
