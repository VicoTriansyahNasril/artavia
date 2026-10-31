import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/finance_calc.dart';
import 'package:artavia/page/budget/budget_controller.dart';
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
          icon: LucideIcons.fileDown,
          semanticLabel: 'Impor anggaran',
          onPressed: controller.importFile,
        ),
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
                const SizedBox(height: 8),
                KButton.text(
                  label: 'Salin ke ${c.period.shift(1).longLabel}',
                  icon: LucideIcons.copy,
                  onPressed: c.isWorking.value ? null : c.copyToNext,
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  /// Add (no [item]) or edit a budget in a bottom sheet: name, one or more
  /// expense categories (or a new one), and the monthly limit.
  void _editSheet([BudgetItem? item]) {
    final c = controller;
    final selected = <int>{...?item?.categoryIds}.obs;
    final name = (item?.name ?? '').obs;
    final iconKey = RxnString(item?.ownIconKey);
    final colorVal = RxnInt(item?.ownColorVal);
    final amount = (item?.limit ?? 0).obs;
    final addingCategory = false.obs;

    Future<void> addCategory() async {
      if (addingCategory.value) return;
      addingCategory.value = true;
      try {
        selected.addAll(await c.addCategory());
      } finally {
        addingCategory.value = false;
      }
    }

    showSheet(
      SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              16, 0, 16, 16 + MediaQuery.viewInsetsOf(Get.context!).bottom),
          child: Obx(() {
            final options = c.availableFor(item);
            final taken = c.nameTaken(name.value, exceptId: item?.id);
            final hint = selected.isEmpty
                ? 'Mis. Makan & jajan'
                : c.defaultName(selected);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(item == null ? 'Anggaran baru' : 'Ubah anggaran',
                    style: AppText.title3.copyWith(color: colorText)),
                const SizedBox(height: 4),
                Text('Batas untuk ${c.period.longLabel}',
                    style: AppText.caption.muted),
                const SizedBox(height: 12),
                KField(
                  label: 'Nama anggaran',
                  hint: hint,
                  initialValue: name.value,
                  maxLength: BudgetController.maxName,
                  textInputAction: TextInputAction.done,
                  state: taken ? KFieldState.error : KFieldState.normal,
                  helper: taken
                      ? 'Nama ini sudah dipakai'
                      : 'Kosongkan untuk memakai nama kategori',
                  onChanged: (v) => name.value = v,
                ),
                const SectionHeader(title: 'Kategori'),
                Text('Pilih satu atau lebih. Pengeluarannya dijumlahkan.',
                    style: AppText.caption.muted),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final cat in options)
                      KChip(
                        label: cat['name'] as String,
                        showCheck: true,
                        selected: selected.contains(cat['id']),
                        onTap: () {
                          final id = cat['id'] as int;
                          if (!selected.remove(id)) selected.add(id);
                        },
                      ),
                    KChip(
                      label: 'Kategori baru',
                      icon: LucideIcons.plus,
                      onTap: addingCategory.value ? null : addCategory,
                    ),
                  ],
                ),
                const SectionHeader(title: 'Ikon & warna'),
                _Appearance(
                  iconKey: iconKey.value ?? _autoIcon(selected),
                  colorVal: colorVal.value ?? _autoColor(selected),
                  custom: iconKey.value != null || colorVal.value != null,
                  onIcon: (k) => iconKey.value = k,
                  onColor: (v) => colorVal.value = v,
                  onReset: () {
                    iconKey.value = null;
                    colorVal.value = null;
                  },
                ),
                const SizedBox(height: 12),
                KAmountField(
                  label: 'Batas per bulan',
                  value: amount.value,
                  onChanged: (n) => amount.value = n,
                ),
                const SizedBox(height: 16),
                KButton(
                  label: 'Simpan anggaran',
                  onPressed: selected.isEmpty ||
                          amount.value <= 0 ||
                          taken ||
                          c.isWorking.value
                      ? null
                      : () => c.save(
                            item: item,
                            name: name.value,
                            categoryIds: {...selected},
                            amount: amount.value,
                            iconKey: iconKey.value,
                            colorVal: colorVal.value,
                          ),
                ),
                if (item != null) ...[
                  const SizedBox(height: 8),
                  KButton.text(
                    label: 'Hapus anggaran',
                    onPressed: () => c.delete(item),
                  ),
                ],
              ],
            );
          }),
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// Icon shown when none is chosen: the only category's, else a tag.
  String _autoIcon(Set<int> ids) {
    final cat = ids.length == 1 ? controller.categoryById(ids.single) : null;
    return IconRegistry.contains(cat?['icon_key'] as String?)
        ? cat!['icon_key'] as String
        : ids.length == 1
            ? IconRegistry.legacyToKey(
                iconPath: cat?['icon_path'] as String?,
                iconCode: cat?['icon_code'] as int?)
            : 'label';
  }

  int? _autoColor(Set<int> ids) => ids.isEmpty
      ? null
      : controller.categoryById(ids.first)?['color_val'] as int?;
}

/// Budget icon + color: preview, "Ganti ikon" (search sheet), palette and
/// "Ikuti kategori" to go back to the automatic look.
class _Appearance extends StatelessWidget {
  final String iconKey;
  final int? colorVal;
  final bool custom;
  final ValueChanged<String> onIcon;
  final ValueChanged<int> onColor;
  final VoidCallback onReset;

  const _Appearance({
    required this.iconKey,
    required this.colorVal,
    required this.custom,
    required this.onIcon,
    required this.onColor,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final color = themedColor(colorVal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CategoryIcon.round(iconKey: iconKey, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(custom ? 'Pilihan sendiri' : 'Mengikuti kategori',
                  style: AppText.caption.muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            KChip(
              label: 'Ganti ikon',
              icon: LucideIcons.search,
              onTap: () async {
                final k = await showIconSearch(selected: iconKey, color: color);
                if (k != null) onIcon(k);
              },
            ),
            if (custom)
              KChip(
                label: 'Ikuti kategori',
                icon: LucideIcons.rotateCcw,
                onTap: onReset,
              ),
          ],
        ),
        const SizedBox(height: 8),
        PaletteColorPicker(value: colorVal ?? -1, onChanged: onColor),
      ],
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
                        flex: 3,
                        child: Text(item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body.copyWith(color: colorText)),
                      ),
                      const SizedBox(width: 8),
                      // Shrinks on narrow screens / large text instead of
                      // overflowing the row.
                      Flexible(
                        flex: 2,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                              '${money.money(item.used)} / ${money.short(item.limit)}',
                              style: AppText.caption.muted),
                        ),
                      ),
                    ],
                  ),
                  if (item.categoryLabel case final cats?)
                    Text(cats,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.muted),
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
        if (c.previousCount.value > 0) ...[
          KButton.text(
            label: 'Salin ${c.previousCount.value} anggaran dari '
                '${c.period.shift(-1).longLabel}',
            icon: LucideIcons.copy,
            onPressed: c.isWorking.value ? null : c.copyFromPrevious,
          ),
          const SizedBox(height: 8),
        ],
        KButton.text(
          label: 'Impor dari file',
          icon: LucideIcons.fileDown,
          onPressed: c.isWorking.value ? null : c.importFile,
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
