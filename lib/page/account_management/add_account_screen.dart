import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/page/account_management/account_management_controller.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// Tambah / ubah rekening: live preview, name, type, balance, credit card
/// fields, color, icon, "tidak dihitung", and archive/delete when editing.
class AddAccountScreen extends GetView<AccountManagementController> {
  const AddAccountScreen({super.key});

  static final _amount = [CurrencyInputFormatter()];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = controller;
      final color = themedColor(c.colorVal.value);
      final version = c.formVersion.value;
      return AppScaffold(
        leading: ScaffoldLeading.close,
        title: c.isEditMode ? 'Ubah rekening' : 'Rekening baru',
        bottom: GlassCard(
          level: GlassLevel.regular,
          borderRadius: BorderRadius.zero,
          shadow: false,
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
          child: KButton(
            label: 'Simpan rekening',
            onPressed: c.isWorking.value ? null : c.saveAccount,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            GlassCard(
              child: Row(
                children: [
                  CategoryIcon.round(
                      iconKey: c.iconKey.value, color: color, diameter: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            c.accountName.value.trim().isEmpty
                                ? 'Nama rekening'
                                : c.accountName.value.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.title3.copyWith(color: colorText)),
                        Text(c.typeValue.value, style: AppText.caption.onGlass),
                      ],
                    ),
                  ),
                  Text(CurrencyService.to.money(c.balance.value),
                      style: AppText.rowAmount.copyWith(color: colorText)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            KField(
              key: ValueKey('name$version'),
              label: 'Nama',
              hint: 'Mis. BCA, GoPay, Dompet',
              initialValue: c.accountName.value,
              maxLength: 30,
              onChanged: (v) => c.accountName.value = v,
            ),
            const SectionHeader(title: 'Jenis'),
            Wrap(
              spacing: 8,
              children: [
                for (final t in AccountManagementController.accountTypes)
                  KChip(
                    label: t,
                    selected: c.typeValue.value == t,
                    onTap: () => c.onTypeSelected(t),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            KField(
              key: ValueKey('balance$version'),
              label: c.isCreditCard ? 'Tagihan saat ini' : 'Saldo',
              hint: '0',
              initialValue: CurrencyInputFormatter.initial(c.balance.value),
              prefix: Text(c.balance.value < 0 ? '−Rp' : 'Rp',
                  style: AppText.body.muted),
              keyboardType: TextInputType.number,
              inputFormatters: _amount,
              helper: c.isCreditCard || c.typeValue.value == 'Pinjaman'
                  ? 'Dicatat sebagai utang (saldo minus).'
                  : null,
              onChanged: (v) {
                final n = CurrencyInputFormatter.parse(v);
                final debt = c.isCreditCard || c.typeValue.value == 'Pinjaman';
                c.balance.value = debt ? -n : n;
              },
            ),
            if (c.isCreditCard) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: KField(
                      key: ValueKey('limit$version'),
                      label: 'Limit',
                      hint: '0',
                      initialValue:
                          CurrencyInputFormatter.initial(c.creditLimit.value),
                      keyboardType: TextInputType.number,
                      inputFormatters: _amount,
                      onChanged: (v) =>
                          c.creditLimit.value = CurrencyInputFormatter.parse(v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: KField(
                      key: ValueKey('due$version'),
                      label: 'Jatuh tempo (tgl)',
                      hint: '1–31',
                      initialValue:
                          c.dueDay.value == null ? '' : '${c.dueDay.value}',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      state: (c.dueDay.value ?? 1) > 31
                          ? KFieldState.error
                          : KFieldState.normal,
                      onChanged: (v) {
                        final n = int.tryParse(v);
                        c.dueDay.value =
                            n == null || n < 1 ? null : (n > 31 ? 31 : n);
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SectionHeader(title: 'Warna'),
            PaletteColorPicker(
              value: c.colorVal.value,
              onChanged: (v) => c.colorVal.value = v,
            ),
            const SectionHeader(title: 'Ikon'),
            IconPicker(
              entries: IconRegistry.accountIcons,
              selected: c.iconKey.value,
              color: color,
              onSelect: (k) => c.iconKey.value = k,
            ),
            const SizedBox(height: 8),
            ListGroup(
              children: [
                NavRow(
                  icon: LucideIcons.eyeOff,
                  title: 'Jangan hitung di kekayaan bersih',
                  subtitle: 'Mis. dana titipan atau rekening bersama',
                  showChevron: false,
                  trailing: KSwitch(
                    value: c.excludeFromTotal.value,
                    semanticLabel: 'Jangan hitung di kekayaan bersih',
                    onChanged: (v) => c.excludeFromTotal.value = v,
                  ),
                  onTap: () =>
                      c.excludeFromTotal.value = !c.excludeFromTotal.value,
                ),
              ],
            ),
            if (c.isEditMode) ...[
              const SizedBox(height: 20),
              KButton.danger(
                label: 'Hapus rekening',
                icon: LucideIcons.trash2,
                onPressed: () => c.deleteAccount({
                  'id': c.editingId.value,
                  'name': c.accountName.value,
                }),
              ),
            ],
          ],
        ),
      );
    });
  }
}
