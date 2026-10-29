import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/database/transaction_store.dart';
import 'package:artavia/core/utils/data_refresh.dart';
import 'package:artavia/widgets/components/app_feedback.dart';

enum BatchState { active, expired, cancelled }

/// Riwayat impor (FR-034): cancel within 7 days, optionally keeping rows
/// that were edited after the import.
class ImportHistoryController extends GetxController {
  static const undoWindow = Duration(days: 7);

  final batches = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async =>
      batches.value = await DatabaseHelper.instance.readImportBatches();

  static BatchState stateOf(Map<String, dynamic> b, [DateTime? now]) {
    if (b['status'] == 'cancelled') return BatchState.cancelled;
    final created = DateTime.parse(b['created_at'] as String);
    return (now ?? DateTime.now()).difference(created) > undoWindow
        ? BatchState.expired
        : BatchState.active;
  }

  /// Days left to cancel (for "Bisa dibatalkan N hari lagi").
  static int daysLeft(Map<String, dynamic> b) {
    final created = DateTime.parse(b['created_at'] as String);
    final left = undoWindow - DateTime.now().difference(created);
    return left.isNegative ? 0 : (left.inHours / 24).ceil();
  }

  Future<void> cancel(Map<String, dynamic> b) async {
    if (stateOf(b) != BatchState.active) return;
    final remaining = b['remaining'] as int;
    final edited = b['edited'] as int;
    bool keepEdited;
    if (edited > 0) {
      final choice = await AppDialog.choose(
        icon: LucideIcons.undo2,
        title: 'Batalkan impor ${b['file_name']}?',
        message: '$edited dari $remaining transaksi sudah diubah setelah '
            'impor. Transaksi yang dihapus mengembalikan saldo rekening.',
        safeLabel: 'Batalkan, simpan $edited yang diubah',
        dangerLabel: 'Batalkan $remaining transaksi',
        cancelLabel: 'Tutup',
      );
      if (choice == DialogChoice.cancel) return;
      keepEdited = choice == DialogChoice.safe;
    } else {
      final ok = await AppDialog.confirm(
        icon: LucideIcons.undo2,
        title: 'Batalkan impor ${b['file_name']}?',
        message: '$remaining transaksi dari impor ini dihapus dan saldo '
            'rekening dikembalikan.',
        confirmLabel: 'Batalkan $remaining transaksi',
        cancelLabel: 'Tutup',
        destructive: true,
      );
      if (!ok) return;
      keepEdited = false;
    }
    final removed = await DatabaseHelper.instance
        .cancelImport(b['id'] as int, keepEdited: keepEdited);
    refreshAllGlobalData();
    await load();
    AppToast.success('Impor dibatalkan', '$removed transaksi dihapus');
  }
}
