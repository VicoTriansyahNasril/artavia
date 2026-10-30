import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/models/recurring_rule.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/date_format.dart';
import 'package:artavia/page/add_transaction/add_transaction_screen.dart';
import 'package:artavia/page/recurring/recurring_controller.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// Transaksi berulang baru / ubah.
class RecurringFormScreen extends GetView<RecurringController> {
  const RecurringFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return AppScaffold(
      leading: ScaffoldLeading.close,
      title: c.editingId == null
          ? 'Transaksi berulang baru'
          : 'Ubah transaksi berulang',
      bottom: GlassCard(
        level: GlassLevel.regular,
        borderRadius: BorderRadius.zero,
        shadow: false,
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
        child: Obx(() => KButton(
              label: 'Simpan',
              onPressed: c.isWorking.value ? null : c.save,
            )),
      ),
      body: Obx(() {
        final account =
            c.accounts.firstWhereOrNull((a) => a['id'] == c.accountId.value);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            KSegment<String>(
              items: const {
                'pengeluaran': 'Pengeluaran',
                'pemasukan': 'Pemasukan',
              },
              value: c.type.value,
              onChanged: c.setType,
            ),
            const SizedBox(height: 16),
            KField(
              controller: c.amountController,
              label: 'Nominal',
              hint: '0',
              prefix: Text('Rp', style: AppText.body.muted),
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
            ),
            const SectionHeader(title: 'Kategori'),
            Wrap(
              spacing: 8,
              children: [
                for (final cat in c.categoriesForType)
                  if (cat['is_archived'] != 1)
                    KChip(
                      label: cat['name'] as String,
                      selected: c.categoryId.value == cat['id'],
                      onTap: () => c.categoryId.value = cat['id'] as int,
                    ),
              ],
            ),
            const SizedBox(height: 8),
            ListGroup(
              children: [
                NavRow(
                  icon: LucideIcons.wallet,
                  title: 'Rekening',
                  trailingText: account?['name'] as String? ?? 'Pilih',
                  onTap: () => showAccountPicker(
                    accounts: c.accounts,
                    selectedId: c.accountId.value,
                    onSelect: (id) => c.accountId.value = id,
                  ),
                ),
                NavRow(
                  icon: LucideIcons.calendar,
                  title: 'Mulai tanggal',
                  trailingText: IdNames.shortDate(c.startDate.value),
                  onTap: () => c.pickStartDate(context),
                ),
              ],
            ),
            const SectionHeader(title: 'Frekuensi'),
            KSegment<RecurringFrequency>(
              height: 40,
              items: {
                for (final f in RecurringFrequency.values) f: f.label,
              },
              value: c.frequency.value,
              onChanged: (f) => c.frequency.value = f,
            ),
            const SizedBox(height: 16),
            KField(
              controller: c.noteController,
              label: 'Catatan (opsional)',
              hint: 'Mis. Gaji, Netflix, Sewa',
              maxLength: 80,
            ),
            if (c.editingId != null) ...[
              const SizedBox(height: 20),
              KButton.danger(
                label: 'Hapus transaksi berulang',
                icon: LucideIcons.trash2,
                onPressed: c.deleteEditing,
              ),
            ],
          ],
        );
      }),
    );
  }
}
