import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/database/transaction_store.dart';
import 'package:artavia/core/services/export_service.dart';
import 'package:artavia/core/services/import_service.dart';
import 'package:artavia/core/utils/data_refresh.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/components/app_feedback.dart';

ParsedFile _parse(Map<String, Object> a) =>
    ImportService.parseImportFile(a['name'] as String, a['bytes'] as Uint8List);

/// Impor 3 langkah (FR-034/035): pilih file → cocokkan kolom → tinjau.
class ImportController extends GetxController {
  final file = Rxn<ParsedFile>();
  final mapping = <ImportField, int?>{}.obs;
  final order = DateOrder.dmy.obs;
  final thousandSep = '.'.obs;
  final preview = Rxn<ImportPreview>();
  final isWorking = false.obs;

  /// NewName.key → existing name to merge into, or null = "Buat baru".
  final resolutions = <String, String?>{}.obs;
  final existingCategoryNames = <String, List<String>>{}.obs;
  final existingAccountNames = <String>[].obs;

  List<String> get missing => ImportService.missingRequired(mapping);

  // ─── Step 1 ──────────────────────────────────────────────────────────────

  Future<void> pickFile() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'csv'],
      dialogTitle: 'Pilih file Excel atau CSV',
    );
    if (picked == null) return;
    isWorking.value = true;
    try {
      final bytes = await picked.readAsBytes();
      final parsed =
          await compute(_parse, {'name': picked.name, 'bytes': bytes});
      file.value = parsed;
      mapping
        ..clear()
        ..addAll(ImportService.guessMapping(parsed.headers));
      _detect();
      Get.toNamed(importMappingRoute);
    } on ImportFileError catch (e) {
      AppToast.error('File tidak bisa dibaca', e.message);
    } catch (_) {
      AppToast.error('File tidak bisa dibaca', 'Pastikan file .xlsx atau .csv');
    } finally {
      isWorking.value = false;
    }
  }

  List<String> samples(ImportField f) {
    final i = mapping[f];
    final rows = file.value?.rows ?? const [];
    if (i == null) return const [];
    return [
      for (final r in rows.take(200))
        if (i < r.length && r[i].trim().isNotEmpty) r[i]
    ];
  }

  void _detect() {
    order.value = ImportService.detectDateOrder(samples(ImportField.date));
    thousandSep.value = ImportService.detectThousandSeparator([
      ...samples(ImportField.amount),
      ...samples(ImportField.fee),
    ]);
  }

  // ─── Step 2 ──────────────────────────────────────────────────────────────

  void setColumn(ImportField field, int? column) {
    if (column != null) {
      // One column feeds one field.
      for (final e in mapping.entries.toList()) {
        if (e.value == column && e.key != field) mapping[e.key] = null;
      }
    }
    mapping[field] = column;
    if (field == ImportField.date ||
        field == ImportField.amount ||
        field == ImportField.fee) {
      _detect();
    }
  }

  Future<void> review() async {
    final f = file.value;
    if (f == null || missing.isNotEmpty) return;
    isWorking.value = true;
    try {
      final db = DatabaseHelper.instance;
      final txs = await db.readAllTransactions();
      final cats = await db.readAllCategories();
      final accs = await db.readAllAccounts();
      existingCategoryNames.value = {
        for (final t in const ['pengeluaran', 'pemasukan'])
          t: [
            for (final c in cats)
              if (c['type'] == t) c['name'] as String
          ],
      };
      existingAccountNames.value = [for (final a in accs) a['name'] as String];
      final active = accs.where((a) => a['is_archived'] != 1).toList();
      preview.value = ImportService.buildPreview(
        f,
        mapping,
        order: order.value,
        thousandSep: thousandSep.value,
        existingKeys: ImportService.keysOf(txs),
        existingCategories: {
          for (final c in cats)
            '${c['type']}|${(c['name'] as String).toLowerCase()}'
        },
        existingAccounts: {
          for (final a in accs) (a['name'] as String).toLowerCase()
        },
        defaultAccount: active.isEmpty ? null : active.first['name'] as String,
      );
      resolutions.clear();
      Get.toNamed(importReviewRoute);
    } finally {
      isWorking.value = false;
    }
  }

  // ─── Step 3 ──────────────────────────────────────────────────────────────

  Future<void> shareProblems() async {
    final f = file.value, pv = preview.value;
    if (f == null || pv == null) return;
    await ExportService.shareText(
        'baris-bermasalah.csv', ImportService.problemsCsv(f, pv.problems));
  }

  void resolve(NewName n, String? mergeInto) => resolutions[n.key] = mergeInto;

  String _resolved(String name, String? type) {
    final merged = resolutions[NewName(name, type).key];
    return merged ?? name;
  }

  Future<void> commit() async {
    final f = file.value, pv = preview.value;
    if (f == null || pv == null || pv.ready.isEmpty || isWorking.value) return;
    isWorking.value = true;
    try {
      await _safetyCopy();
      final rows = [
        for (final r in pv.ready)
          {
            'type': r.type,
            'amount': r.amount,
            if (r.category != null) 'category': _resolved(r.category!, r.type),
            'account': _resolved(r.account, null),
            if (r.destination != null)
              'destination_account': _resolved(r.destination!, null),
            'admin_fee': r.fee,
            'note': r.note,
            'date': r.date.toIso8601String(),
          },
      ];
      await DatabaseHelper.instance.importBatch(f.name, rows,
          newCategoryColor: (i) =>
              categoryPaletteValues[(i + 4) % categoryPaletteValues.length]);
      refreshAllGlobalData();
      Get.until((route) => route.settings.name == exportRoute);
      AppToast.toast(
        icon: LucideIcons.circleCheck,
        tone: colorIncome,
        title: '${rows.length} transaksi diimpor',
        body: 'Bisa dibatalkan selama 7 hari di Riwayat impor.',
        actions: [
          ToastAction('Riwayat impor', () => Get.toNamed(importHistoryRoute),
              primary: true),
        ],
      );
    } catch (e) {
      AppToast.error('Impor gagal', 'Tidak ada data yang diubah');
    } finally {
      isWorking.value = false;
    }
  }

  /// Local copy of the DB file before writing anything (research R9).
  Future<void> _safetyCopy() async {
    final dir = await getApplicationDocumentsDirectory();
    await File(await DatabaseHelper.instance.databaseFilePath())
        .copy(p.join(dir.path, 'artavia-sebelum-impor.db'));
  }
}
