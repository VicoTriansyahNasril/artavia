import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/services/import_service.dart';
import 'package:artavia/page/data_transfer/import_controller.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// Impor step 3 (board): ready / duplicate / problem tiles, problem rows
/// (+ download), new category/account resolution, "Impor N transaksi".
class ImportReviewScreen extends GetView<ImportController> {
  const ImportReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = controller;
      final pv = c.preview.value;
      if (pv == null) return const SizedBox.shrink();
      c.resolutions.length;
      return AppScaffold(
        leading: ScaffoldLeading.back,
        title: 'Tinjau impor',
        bottom: GlassCard(
          level: GlassLevel.regular,
          borderRadius: BorderRadius.zero,
          shadow: false,
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
          child: KButton(
            label: c.isWorking.value
                ? 'Mengimpor…'
                : 'Impor ${pv.ready.length} transaksi',
            icon: LucideIcons.fileDown,
            onPressed: pv.ready.isEmpty || c.isWorking.value ? null : c.commit,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            const StepHeader(step: 3, label: 'Tinjau'),
            const SizedBox(height: 12),
            StatTiles(items: [
              StatItem(
                  value: '${pv.ready.length}',
                  label: 'Siap diimpor',
                  tone: StatTone.success),
              StatItem(value: '${pv.duplicates.length}', label: 'Duplikat'),
              StatItem(
                  value: '${pv.problems.length}',
                  label: 'Bermasalah',
                  tone: StatTone.danger),
            ]),
            if (pv.duplicates.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                    '${pv.duplicates.length} transaksi sudah ada dan dilewati.',
                    style: AppText.caption.muted),
              ),
            if (pv.problems.isNotEmpty)
              ListGroup(
                title: 'Baris bermasalah (tidak diimpor)',
                titleAction: KButton.text(
                  label: 'Unduh daftar',
                  compact: true,
                  expand: false,
                  onPressed: c.shareProblems,
                ),
                children: [
                  for (final p in pv.problems.take(20))
                    NavRow(
                      leading: SizedBox(
                        width: 40,
                        child: Text('#${p.line}',
                            style: AppText.label.copyWith(color: colorDanger)),
                      ),
                      title: p.reason,
                      subtitle: p.raw.where((v) => v.isNotEmpty).join(' · '),
                      showChevron: false,
                    ),
                  if (pv.problems.length > 20)
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                          '+${pv.problems.length - 20} baris lain di daftar unduhan',
                          style: AppText.caption.muted),
                    ),
                ],
              ),
            if (pv.newCategories.isNotEmpty)
              ListGroup(
                title: 'Kategori baru',
                children: [
                  for (final n in pv.newCategories)
                    _Resolution(
                      c: c,
                      name: n,
                      subtitle:
                          n.type == 'pemasukan' ? 'Pemasukan' : 'Pengeluaran',
                      options: c.existingCategoryNames[n.type] ?? const [],
                    ),
                ],
              ),
            if (pv.newAccounts.isNotEmpty)
              ListGroup(
                title: 'Rekening baru',
                children: [
                  for (final n in pv.newAccounts)
                    _Resolution(
                      c: c,
                      name: n,
                      subtitle: 'Saldo awal 0',
                      options: c.existingAccountNames,
                    ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.undo2, size: 16, color: colorGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Impor bisa dibatalkan selama 7 hari di Riwayat impor.',
                      style: AppText.caption.muted),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

/// "Buat baru" / "Gabung: X" for one new name.
class _Resolution extends StatelessWidget {
  final ImportController c;
  final NewName name;
  final String subtitle;
  final List<String> options;

  const _Resolution({
    required this.c,
    required this.name,
    required this.subtitle,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final merged = c.resolutions[name.key];
    return NavRow(
      icon: merged == null ? LucideIcons.plus : LucideIcons.merge,
      title: name.name,
      subtitle: subtitle,
      trailingText: merged == null ? 'Buat baru' : 'Gabung: $merged',
      trailingColor: colorAccent,
      onTap: options.isEmpty ? null : _choose,
    );
  }

  void _choose() {
    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('"${name.name}"',
                  style: AppText.title3.copyWith(color: colorText)),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: ListGroup(
                    dividerInset: 14,
                    children: [
                      NavRow(
                        title: 'Buat baru',
                        showChevron: false,
                        trailing:
                            KRadio(selected: c.resolutions[name.key] == null),
                        onTap: () {
                          Get.back();
                          c.resolve(name, null);
                        },
                      ),
                      for (final o in options)
                        NavRow(
                          title: 'Gabung: $o',
                          showChevron: false,
                          trailing:
                              KRadio(selected: c.resolutions[name.key] == o),
                          onTap: () {
                            Get.back();
                            c.resolve(name, o);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
