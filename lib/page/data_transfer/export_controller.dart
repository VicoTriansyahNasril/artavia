import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/services/export_service.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/widgets/components/app_feedback.dart';

/// Ekspor (FR-034): format, period, parts with counts, preview.
class ExportController extends GetxController {
  static const ranges = ['Bulan ini', 'Tahun ini', 'Semua', 'Pilih…'];

  final tab = 0.obs; // 0 = Ekspor, 1 = Impor
  final format = ExportFormat.xlsx.obs;
  final rangeLabel = 'Bulan ini'.obs;
  final custom = Rxn<DateTimeRange>();
  final parts = <ExportPart>{...ExportPart.values}.obs;
  final counts = <ExportPart, int>{}.obs;
  final previewRows = <List<Object?>>[].obs;
  final isWorking = false.obs;

  ExportRange get range {
    final now = DateTime.now();
    switch (rangeLabel.value) {
      case 'Bulan ini':
        final p = PeriodService.to.active.value;
        return ExportRange(p.longLabel, p.start, p.end);
      case 'Tahun ini':
        return ExportRange(
            '${now.year}', DateTime(now.year), DateTime(now.year + 1));
      case 'Pilih…':
        final r = custom.value;
        if (r != null) {
          return ExportRange('Rentang pilihan', r.start,
              DateTime(r.end.year, r.end.month, r.end.day + 1));
        }
        return const ExportRange('Semua data');
      default:
        return const ExportRange('Semua data');
    }
  }

  int get transactionCount => counts[ExportPart.transactions] ?? 0;

  /// What will actually be written (CSV = transactions only).
  Set<ExportPart> get effectiveParts =>
      format.value == ExportFormat.csv ? {ExportPart.transactions} : parts;

  bool get canExport =>
      effectiveParts.isNotEmpty &&
      (!effectiveParts.contains(ExportPart.transactions) ||
          transactionCount > 0 ||
          effectiveParts.length > 1);

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['tab'] == 1) tab.value = 1;
    load();
  }

  Future<void> load() async {
    counts.value = await ExportService.counts(range);
    // Query results are read-only; copy before sorting.
    final rows = [...await ExportService.transactionsIn(range)];
    rows.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    previewRows.value =
        rows.take(4).map(ExportService.transactionCells).toList();
  }

  void setFormat(ExportFormat f) => format.value = f;

  Future<void> setRange(String label, BuildContext context) async {
    if (label == 'Pilih…') {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(now.year + 1, 12, 31),
        initialDateRange: custom.value,
        helpText: 'Pilih rentang tanggal',
      );
      if (picked == null) return;
      custom.value = picked;
    }
    rangeLabel.value = label;
    await load();
  }

  void togglePart(ExportPart p) {
    if (!parts.remove(p)) parts.add(p);
  }

  Future<void> export() async {
    if (isWorking.value || !canExport) return;
    isWorking.value = true;
    try {
      await ExportService.exportAndShare(
        format: format.value,
        range: range,
        parts: effectiveParts,
      );
    } catch (e) {
      AppToast.error('Ekspor gagal', 'File tidak dapat dibuat');
    } finally {
      isWorking.value = false;
    }
  }
}
