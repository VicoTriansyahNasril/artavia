import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/finance_calc.dart';
import 'package:artavia/page/budget/budget_controller.dart';
import 'package:artavia/widgets/components/app_feedback.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// Anggaran (board): hero, Perlu perhatian / Aman, empty state with
/// suggestions.
class BudgetScreen extends GetView<BudgetController> {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      leading: ScaffoldLeading.back,
      title: 'Anggaran',
      actions: [
        KIconButton(
          icon: LucideIcons.plus,
          semanticLabel: 'Tambah anggaran',
          onPressed: () => _editSheet(),
        ),
      ],
      body: Obx(() {
        final c = controller;
        final items = c.items;
        c.suggestions.length;
        return RefreshIndicator(
          onRefresh: c.loadData,
          backgroundColor: colorCard,
          color: colorAccent,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              Row(
                children: [
                  KIconButton(
                    icon: LucideIcons.chevronLeft,
                    semanticLabel: 'Bulan sebelumnya',
                    onPressed: () => c.shift(-1),
                  ),
                  Expanded(
                    child: Text(c.period.longLabel,
                        textAlign: TextAlign.center,
                        style: AppText.title3.copyWith(color: colorText)),
                  ),
                  KIconButton(
                    icon: LucideIcons.chevronRight,
                    semanticLabel: 'Bulan berikutnya',
                    onPressed: () => c.shift(1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (items.isEmpty && !c.isLoading.value)
                _Empty(controller: c, onCreate: _editSheet)
              else if (items.isNotEmpty) ...[
                _Hero(controller: c),
                if (c.attention.isNotEmpty)
                  ListGroup(
                    title: 'Perlu perhatian',
                    children: [
                      for (final i in c.attention)
                        _BudgetRow(item: i, onTap: () => _editSheet(i)),
                    ],
                  ),
                if (c.safe.isNotEmpty)
                  ListGroup(
                    title: 'Aman',
                    children: [
                      for (final i in c.safe)
                        _BudgetRow(item: i, onTap: () => _editSheet(i)),
                    ],
                  ),
              ],
            ],
          ),
        );
      }),
    );
  }

  /// Add (no [item]) or edit a budget in a bottom sheet.
  void _editSheet([BudgetItem? item]) {
    final c = controller;
    if (item == null && c.unbudgeted.isEmpty) {
      AppToast.info('Semua kategori sudah dianggarkan',
          'Ketuk salah satu anggaran untuk mengubahnya.');
      return;
    }
    final categoryId = RxnInt(item?.categoryId);
    final amount = (item?.limit ?? 0).obs;
    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              16, 0, 16, 16 + MediaQuery.viewInsetsOf(Get.context!).bottom),
          child: Obx(() => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(item == null ? 'Anggaran baru' : 'Anggaran ${item.name}',
                      style: AppText.title3.copyWith(color: colorText)),
                  const SizedBox(height: 4),
                  Text('Batas untuk ${c.period.longLabel}',
                      style: AppText.caption.muted),
                  if (item == null) ...[
                    const SectionHeader(title: 'Kategori'),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final cat in c.unbudgeted)
                          KChip(
                            label: cat['name'] as String,
                            selected: categoryId.value == cat['id'],
                            onTap: () => categoryId.value = cat['id'] as int,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  KField(
                    label: 'Batas per bulan',
                    hint: '0',
                    autofocus: item != null,
                    initialValue: item == null ? '' : '${item.limit}',
                    prefix: Text('Rp', style: AppText.body.muted),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    onChanged: (v) => amount.value = int.tryParse(v) ?? 0,
                  ),
                  const SizedBox(height: 16),
                  KButton(
                    label: 'Simpan anggaran',
                    onPressed: categoryId.value == null || amount.value <= 0
                        ? null
                        : () => c.save(categoryId.value!, amount.value),
                  ),
                  if (item != null) ...[
                    const SizedBox(height: 8),
                    KButton.text(
                      label: 'Hapus anggaran',
                      onPressed: () => c.delete(item),
                    ),
                  ],
                ],
              )),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _Hero extends StatelessWidget {
  final BudgetController controller;
  const _Hero({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final money = CurrencyService.to;
    final level = budgetStatus(c.totalUsed, c.totalLimit);
    final tone = switch (level) {
      BudgetLevel.over => KTone.danger,
      BudgetLevel.near => KTone.warning,
      BudgetLevel.safe => KTone.accent,
    };
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.remaining >= 0 ? 'Sisa anggaran' : 'Lewat anggaran',
              style: AppText.caption.onGlass),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(money.money(c.remaining.abs()),
                style: AppText.amountL.copyWith(
                    color: c.remaining >= 0 ? colorText : colorDanger)),
          ),
          Text('dari ${money.money(c.totalLimit)} · ${c.daysLeft} hari lagi',
              style: AppText.caption.onGlass),
          const SizedBox(height: 12),
          KProgress(
              value: c.totalLimit == 0 ? 0 : c.totalUsed / c.totalLimit,
              tone: tone),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.shieldCheck, size: 16, color: colorAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    c.safeDaily > 0
                        ? 'Aman dibelanjakan ± ${money.money(c.safeDaily)} per hari'
                        : 'Tidak ada sisa untuk dibelanjakan periode ini',
                    style: AppText.caption.onGlass),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final BudgetItem item;
  final VoidCallback onTap;
  const _BudgetRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final money = CurrencyService.to;
    final (KTone tone, Color text, String status) = switch (item.level) {
      BudgetLevel.over => (
          KTone.danger,
          colorDanger,
          'Lewat ${money.money(-item.left)}'
        ),
      BudgetLevel.near => (
          KTone.warning,
          colorWarning,
          '${(item.ratio * 100).round()}% · sisa ${money.money(item.left)}'
        ),
      BudgetLevel.safe => (
          KTone.accent,
          colorGrey,
          'Sisa ${money.money(item.left)}'
        ),
    };
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CategoryIcon.round(
              iconKey: item.iconKey,
              iconPath: item.iconPath,
              iconCode: item.iconCode,
              color: themedColor(item.colorVal),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body.copyWith(color: colorText)),
                      ),
                      Text(
                          '${money.money(item.used)} / ${money.short(item.limit)}',
                          style: AppText.caption.muted),
                    ],
                  ),
                  const SizedBox(height: 6),
                  KProgress(value: item.ratio, tone: tone, height: 5),
                  const SizedBox(height: 4),
                  Text(status, style: AppText.caption.copyWith(color: text)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final BudgetController controller;
  final VoidCallback onCreate;
  const _Empty({required this.controller, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final money = CurrencyService.to;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmptyState(
          icon: LucideIcons.target,
          title: 'Belum ada anggaran',
          body: 'Tetapkan batas per kategori supaya pengeluaran tetap '
              'terkendali.',
          action: KButton.tonal(
            label: 'Buat anggaran',
            icon: LucideIcons.plus,
            onPressed: onCreate,
          ),
        ),
        if (c.suggestions.isNotEmpty)
          ListGroup(
            title: 'Saran dari rata-rata 3 bulan',
            titleAction: KButton.text(
              label: 'Pakai semua',
              compact: true,
              expand: false,
              onPressed: c.useAllSuggestions,
            ),
            children: [
              for (final s in c.suggestions)
                NavRow(
                  leading: CategoryIcon.round(
                    iconKey: s.category['icon_key'] as String?,
                    iconPath: s.category['icon_path'] as String?,
                    iconCode: s.category['icon_code'] as int?,
                    color: themedColor(s.category['color_val'] as int?),
                  ),
                  title: s.category['name'] as String,
                  subtitle: '${money.money(s.amount)} per bulan',
                  showChevron: false,
                  trailing: KButton.tonal(
                    label: 'Pakai',
                    onPressed: () => c.useSuggestion(s),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
