import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/services/export_service.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/page/data_transfer/export_controller.dart';
import 'package:artavia/page/data_transfer/import_controller.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// Ekspor & impor (board): segment, export form with sticky CTA; the Impor
/// tab is step 1 of the import flow.
class ExportScreen extends GetView<ExportController> {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = controller;
      final exporting = c.tab.value == 0;
      // The body is a plain widget: read what it shows here.
      c.rangeLabel.value;
      c.custom.value;
      c.previewRows.length;
      c.counts.length;
      return AppScaffold(
        leading: ScaffoldLeading.back,
        title: 'Ekspor & impor',
        actions: [
          KIconButton(
            icon: LucideIcons.history,
            semanticLabel: 'Riwayat impor',
            onPressed: () => Get.toNamed(importHistoryRoute),
          ),
        ],
        bottom: exporting
            ? GlassCard(
                level: GlassLevel.regular,
                borderRadius: BorderRadius.zero,
                shadow: false,
                padding: EdgeInsets.fromLTRB(
                    16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
                child: KButton(
                  label: c.isWorking.value
                      ? 'Menyiapkan file…'
                      : c.effectiveParts.contains(ExportPart.transactions)
                          ? 'Ekspor ${c.transactionCount} transaksi'
                          : 'Ekspor',
                  icon: LucideIcons.share2,
                  onPressed:
                      c.canExport && !c.isWorking.value ? c.export : null,
                ),
              )
            : null,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: KSegment<int>(
                items: const {0: 'Ekspor', 1: 'Impor'},
                value: c.tab.value,
                onChanged: (v) => c.tab.value = v,
              ),
            ),
            Expanded(
              child: exporting ? _ExportBody(c: c) : const _ImportStart(),
            ),
          ],
        ),
      );
    });
  }
}

class _ExportBody extends StatelessWidget {
  final ExportController c;
  const _ExportBody({required this.c});

  @override
  Widget build(BuildContext context) {
    final csv = c.format.value == ExportFormat.csv;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const SectionHeader(title: 'Format'),
        Row(
          children: [
            Expanded(
              child: _FormatCard(
                icon: LucideIcons.fileSpreadsheet,
                title: 'Excel (.xlsx)',
                body: 'Satu lembar per jenis data',
                selected: !csv,
                onTap: () => c.setFormat(ExportFormat.xlsx),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FormatCard(
                icon: LucideIcons.fileText,
                title: 'CSV',
                body: 'Hanya transaksi',
                selected: csv,
                onTap: () => c.setFormat(ExportFormat.csv),
              ),
            ),
          ],
        ),
        const SectionHeader(title: 'Periode'),
        Wrap(
          spacing: 8,
          children: [
            for (final r in ExportController.ranges)
              KChip(
                label: r == 'Pilih…' && c.rangeLabel.value == r
                    ? c.range.label
                    : r,
                selected: c.rangeLabel.value == r,
                onTap: () => c.setRange(r, context),
              ),
          ],
        ),
        const SectionHeader(title: 'Isi file'),
        ListGroup(
          children: [
            for (final p in ExportPart.values)
              Opacity(
                opacity: csv && p != ExportPart.transactions ? 0.4 : 1,
                child: NavRow(
                  title:
                      p == ExportPart.accounts ? 'Rekening & saldo' : p.sheet,
                  subtitle: '${c.counts[p] ?? 0} baris',
                  showChevron: false,
                  trailing: KCheck(
                    value: c.effectiveParts.contains(p),
                    semanticLabel: p.sheet,
                    onChanged: csv ? null : (_) => c.togglePart(p),
                  ),
                  onTap: csv ? null : () => c.togglePart(p),
                ),
              ),
          ],
        ),
        if (c.previewRows.isNotEmpty) ...[
          const SectionHeader(title: 'Pratinjau'),
          KCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _previewRow(['Tanggal', 'Jenis', 'Jumlah', 'Kategori'],
                    header: true),
                for (final r in c.previewRows)
                  _previewRow([
                    '${r[0]}',
                    '${r[2]}',
                    CurrencyService.to.digits(r[3] as int),
                    '${r[4]}'
                  ]),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static Widget _previewRow(List<String> cells, {bool header = false}) {
    final style = header
        ? AppText.caption.w600.copyWith(color: colorGrey)
        : AppText.caption.copyWith(color: colorText);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: i == 3 ? 3 : 2,
              child: Text(cells[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: i == 2 ? TextAlign.end : TextAlign.start,
                  style: style),
            ),
        ],
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  const _FormatCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? colorAccentDim : colorCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? colorAccent : colorDivider,
                width: selected ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: selected ? colorAccent : colorGrey),
              const SizedBox(height: 8),
              Text(title,
                  style: AppText.bodySmall.w600.copyWith(color: colorText)),
              Text(body, style: AppText.caption.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Impor step 1: choose a file, what can be imported, template, safety.
class _ImportStart extends GetView<ImportController> {
  const _ImportStart();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const StepHeader(step: 1, label: 'Pilih file'),
        const SizedBox(height: 16),
        Obx(() => GestureDetector(
              onTap: controller.isWorking.value ? null : controller.pickFile,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  color: colorCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorDivider, width: 1.5),
                ),
                child: Column(
                  children: [
                    if (controller.isWorking.value)
                      const CircularProgressIndicator()
                    else
                      Icon(LucideIcons.fileUp, size: 32, color: colorAccent),
                    const SizedBox(height: 10),
                    Text('Pilih file Excel atau CSV',
                        style: AppText.title3.copyWith(color: colorText)),
                    const SizedBox(height: 4),
                    Text('Dari HP atau Google Drive · maks. 20 MB',
                        textAlign: TextAlign.center,
                        style: AppText.caption.muted),
                    const SizedBox(height: 14),
                    KButton.tonal(
                      label: 'Pilih file',
                      icon: LucideIcons.folderOpen,
                      onPressed: controller.isWorking.value
                          ? null
                          : controller.pickFile,
                    ),
                  ],
                ),
              ),
            )),
        const ListGroup(
          title: 'Yang bisa diimpor',
          children: [
            NavRow(
              icon: LucideIcons.calendar,
              title: 'Tanggal & jumlah (wajib)',
              subtitle: 'Format tanggal dan pemisah ribuan dikenali otomatis',
            ),
            NavRow(
              icon: LucideIcons.tags,
              title: 'Jenis, kategori, rekening, catatan',
              subtitle: 'Kategori & rekening baru bisa dibuat atau digabung',
            ),
            NavRow(
              icon: LucideIcons.copyCheck,
              title: 'Duplikat dilewati',
              subtitle: 'Transaksi yang sudah ada tidak dicatat dua kali',
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Align(
          alignment: Alignment.centerLeft,
          child: KButton.text(
            label: 'Unduh template Excel',
            icon: LucideIcons.download,
            expand: false,
            onPressed: ExportService.shareTemplate,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: colorAccentDim, borderRadius: BorderRadius.circular(12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.shieldCheck, size: 16, color: colorAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Data lama tidak ditimpa. Salinan data dibuat otomatis '
                    'sebelum impor, dan impor bisa dibatalkan selama 7 hari.',
                    style: AppText.caption.copyWith(color: colorAccent)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
