import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/transfer_math.dart';
import 'package:artavia/page/add_transaction/add_transaction_controller.dart';
import 'package:artavia/page/add_transaction/add_transaction_screen.dart';
import 'package:artavia/page/transfer/transfer_controller.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// Transfer segment of Catat (board "Transfer"): Dari/Ke with balances and
/// swap, amount field, remembered admin fee chips, who pays it, and a live
/// summary with a non-blocking low-balance warning.
class TransferSection extends GetView<TransferController> {
  const TransferSection({super.key});

  AddTransactionController get _catat => Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // The parts below are plain widgets; read everything they show here
      // so this Obx rebuilds them on every change.
      controller
        ..amount.value
        ..activeField.value
        ..customFee.value
        ..remembered.value
        ..sourceId.value
        ..destId.value;
      _catat.expression.value;
      if (controller.accounts.length < 2) {
        return EmptyState(
          icon: LucideIcons.arrowRightLeft,
          title: 'Butuh dua rekening',
          body: 'Tambahkan rekening kedua untuk memindahkan saldo.',
          action: KButton.tonal(
            label: 'Tambah rekening',
            icon: LucideIcons.plus,
            onPressed: _catat.createAccount,
          ),
        );
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          _PairCard(controller: controller),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: _label('Jumlah transfer', bottom: 0)),
                const CatatDateChip(),
              ],
            ),
          ),
          _AmountField(controller: controller),
          const SizedBox(height: 16),
          _label('Biaya admin'),
          _FeeChips(controller: controller),
          if (controller.fee.value > 0) ...[
            const SizedBox(height: 12),
            _label('Dipotong dari'),
            KSegment<FeeBearer>(
              height: 40,
              items: {
                FeeBearer.sender:
                    'Saldo ${controller.nameOf(controller.sourceId.value)}',
                FeeBearer.receiver: 'Uang diterima',
              },
              value: controller.bearer.value,
              onChanged: controller.setBearer,
            ),
          ],
          const SizedBox(height: 16),
          _Summary(controller: controller),
        ],
      );
    });
  }

  static Widget _label(String text, {double bottom = 8}) => Padding(
        padding: EdgeInsets.only(left: 4, bottom: bottom),
        child: Text(text, style: AppText.label.copyWith(color: colorGrey)),
      );
}

class _PairCard extends StatelessWidget {
  final TransferController controller;
  const _PairCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return KCard(
      child: Stack(
        children: [
          Column(
            children: [
              _side('Dari', c.sourceId.value,
                  () => _pick('Transfer dari', c.sourceId.value, c.setSource)),
              Padding(
                padding: const EdgeInsets.only(left: 68),
                child: Divider(height: 1, color: colorDivider),
              ),
              _side('Ke', c.destId.value,
                  () => _pick('Transfer ke', c.destId.value, c.setDestination)),
            ],
          ),
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: Material(
                color: colorSurface,
                shape: CircleBorder(side: BorderSide(color: colorDivider)),
                child: KIconButton(
                  icon: LucideIcons.arrowUpDown,
                  size: 18,
                  color: colorAccent,
                  semanticLabel: 'Tukar rekening asal dan tujuan',
                  onPressed: c.swap,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _side(String label, int? id, VoidCallback onTap) {
    final acc = controller.accounts.firstWhereOrNull((a) => a['id'] == id);
    final index = controller.accounts.indexWhere((a) => a['id'] == id);
    return NavRow(
      leading: CategoryIcon.round(
        iconKey: acc?['icon_key'] as String? ??
            IconRegistry.accountTypeKey(acc?['type'] as String? ?? ''),
        color: themedColor(acc?['color_val'] as int?,
            fallbackIndex: index < 0 ? 0 : index),
      ),
      title: acc?['name'] as String? ?? 'Pilih rekening',
      subtitle:
          '$label · Saldo ${CurrencyService.to.money(controller.balanceOf(id))}',
      showChevron: false,
      trailing: const SizedBox(width: 44),
      onTap: onTap,
    );
  }

  void _pick(String title, int? selected, ValueChanged<int> onSelect) {
    showAccountPicker(
      title: title,
      accounts: controller.accounts,
      selectedId: selected,
      onSelect: onSelect,
    );
  }
}

/// Read-only amount display; tapping it points the keypad at the amount.
class _AmountField extends StatelessWidget {
  final TransferController controller;
  const _AmountField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final catat = Get.find<AddTransactionController>();
    final active = c.activeField.value == TransferField.amount;
    final warn = c.preview.shortfall > 0;
    final ring = warn
        ? BorderSide(color: colorWarning, width: 1.5)
        : active
            ? BorderSide(color: colorAccent, width: 1.5)
            : BorderSide(color: colorDivider);
    final expr = catat.expression.value;
    return Semantics(
      button: true,
      label:
          'Jumlah transfer ${CurrencyService.to.money(c.amount.value, maskable: false)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: c.focusAmount,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colorCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.fromBorderSide(ring),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (expr.isNotEmpty)
                Text(expr, style: AppText.caption.muted, maxLines: 1),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                        '${c.amount.value < 0 ? CurrencyService.minus : ''}Rp ',
                        style: AppText.currencyPrefix.muted),
                    Text(
                        CurrencyService.to
                            .digits(c.amount.value.abs(), maskable: false),
                        style: AppText.title1.copyWith(
                            color:
                                c.amount.value < 0 ? colorDanger : colorText)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeeChips extends StatelessWidget {
  final TransferController controller;
  const _FeeChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final money = CurrencyService.to;
    final remembered = c.remembered.value?.fee;
    final custom = c.customFee.value;
    final chips = c.feeChips;
    final presetSelected =
        !custom && (c.fee.value == 0 || chips.contains(c.fee.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            KChip(
              label: 'Tidak ada',
              selected: !custom && c.fee.value == 0,
              onTap: () => c.pickFee(0),
            ),
            for (final f in chips)
              KChip(
                label: money.digits(f, maskable: false),
                icon: f == remembered ? LucideIcons.history : null,
                selected: !custom && c.fee.value == f,
                onTap: () => c.pickFee(f),
              ),
            KChip(
              label: custom || presetSelected
                  ? 'Isi sendiri'
                  : money.digits(c.fee.value, maskable: false),
              icon: LucideIcons.pencil,
              selected: custom || !presetSelected,
              onTap: c.startCustomFee,
            ),
          ],
        ),
        if (custom) ...[
          const SizedBox(height: 8),
          _FeeField(controller: c),
        ],
      ],
    );
  }
}

class _FeeField extends StatelessWidget {
  final TransferController controller;
  const _FeeField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final active = c.editingFee;
    final error = c.preview.error != null;
    return Semantics(
      button: true,
      label:
          'Biaya admin ${CurrencyService.to.money(c.fee.value, maskable: false)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: c.focusFee,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: colorCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.fromBorderSide(error
                ? BorderSide(color: colorDanger, width: 1.5)
                : active
                    ? BorderSide(color: colorAccent, width: 1.5)
                    : BorderSide(color: colorDivider)),
          ),
          child: Row(
            children: [
              Text('Rp ', style: AppText.body.muted),
              Text(CurrencyService.to.digits(c.fee.value, maskable: false),
                  style: AppText.title3.copyWith(color: colorText)),
              const Spacer(),
              if (active)
                Text('Isi dengan papan angka', style: AppText.caption.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final TransferController controller;
  const _Summary({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final p = c.preview;
    final money = CurrencyService.to;
    final src = c.nameOf(c.sourceId.value);
    final dst = c.nameOf(c.destId.value);
    final lines = <Widget>[];

    if (p.error != null) {
      lines.add(_line(LucideIcons.circleAlert, p.error!, colorDanger));
    } else if (c.amount.value > 0) {
      lines.add(Text(
        '$src ${money.money(p.sourceDelta, signed: true, maskable: false)}'
        '  →  $dst ${money.money(p.destDelta, signed: true, maskable: false)}',
        style: AppText.bodySmall.w600.copyWith(color: colorText),
      ));
      lines.add(Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          p.fee == 0
              ? 'Tanpa biaya. Saldo berpindah utuh.'
              : 'Biaya admin ${money.money(p.fee, maskable: false)} dicatat '
                  'sebagai pengeluaran.',
          style: AppText.caption.muted,
        ),
      ));
    }
    if (p.shortfall > 0) {
      lines.add(Padding(
        padding: const EdgeInsets.only(top: 8),
        child: _line(
          LucideIcons.triangleAlert,
          'Saldo $src kurang ${money.money(p.shortfall, maskable: false)}. '
          'Tetap bisa disimpan, saldo jadi minus.',
          colorWarning,
        ),
      ));
    }
    if (lines.isEmpty) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: lines),
      ),
    );
  }

  static Widget _line(IconData icon, String text, Color tone) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: tone),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: AppText.caption.copyWith(color: tone))),
        ],
      );
}
