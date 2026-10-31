import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/database/transaction_store.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/data_refresh.dart';
import 'package:artavia/core/utils/finance_calc.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/components/app_feedback.dart';

/// Kategori (US6): per-type list in manual order, drag to reorder,
/// archive/restore, counts + budget subtitle, and the add/edit form with
/// 12 colors and 107 icons (FR-025, FR-026, FR-021).
class CategoryManagementController extends GetxController {
  static const maxName = 30;

  /// 'pengeluaran' or 'pemasukan'.
  final currentType = 'pengeluaran'.obs;

  final expense = <Map<String, dynamic>>[].obs;
  final income = <Map<String, dynamic>>[].obs;
  final archived = <Map<String, dynamic>>[].obs;
  final counts = <int, int>{}.obs;

  /// Category id → subtitle label of the budget holding it this period.
  final budgets = <int, String>{}.obs;
  final isWorking = false.obs;

  // ─── Form ────────────────────────────────────────────────────────────────
  final editingId = RxnInt();
  bool get isEditMode => editingId.value != null;
  final name = ''.obs;
  final formType = 'pengeluaran'.obs;
  final iconKey = 'lainnya'.obs;
  final colorVal = categoryPaletteValues.first.obs;
  final formVersion = 0.obs;

  List<Map<String, dynamic>> get visible =>
      currentType.value == 'pengeluaran' ? expense : income;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['type'] is String) {
      currentType.value = args['type'] as String;
      resetForm(type: currentType.value);
    }
    loadCategories();
  }

  Future<void> loadCategories() async {
    final db = DatabaseHelper.instance;
    final cats = await db.readAllCategories();
    counts.value = await db.transactionCountByCategory();
    final p = PeriodService.to.active.value;
    budgets.value = {
      for (final b in await db.readBudgetsByMonth(p.year, p.month))
        for (final id in b['category_ids'] as List<int>)
          id: (b['category_ids'] as List).length == 1
              ? CurrencyService.to.short(b['budget_amount'] as int)
              : b['name'] as String,
    };
    final active = cats.where((c) => c['is_archived'] != 1);
    expense.value = active.where((c) => c['type'] == 'pengeluaran').toList();
    income.value = active.where((c) => c['type'] == 'pemasukan').toList();
    archived.value = cats.where((c) => c['is_archived'] == 1).toList();
  }

  void changeType(String type) => currentType.value = type;

  /// Drag-to-reorder within the visible type; persisted immediately.
  /// [newIndex] is already adjusted for the removed item.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = List<Map<String, dynamic>>.of(visible);
    list.insert(newIndex, list.removeAt(oldIndex));
    if (currentType.value == 'pengeluaran') {
      expense.value = list;
    } else {
      income.value = list;
    }
    await DatabaseHelper.instance
        .saveSortOrder('categories', [for (final c in list) c['id'] as int]);
    refreshAllGlobalData();
  }

  /// One-tap fill of the manual order from how often each category of the
  /// visible type is used (ties keep their current order).
  Future<void> sortByUsage() async {
    final ok = await AppDialog.confirm(
      icon: LucideIcons.arrowDownWideNarrow,
      title: 'Urutkan menurut pemakaian?',
      message: 'Kategori yang paling sering dipakai pindah ke atas, dan '
          'urutan di Catat ikut berubah. Setelahnya kamu tetap bisa '
          'menggeser manual.',
      confirmLabel: 'Urutkan',
    );
    if (!ok) return;
    final db = DatabaseHelper.instance;
    final list =
        rankCategories(visible, await db.categoryUsage(currentType.value));
    if (currentType.value == 'pengeluaran') {
      expense.value = list;
    } else {
      income.value = list;
    }
    await db.saveSortOrder('categories', [for (final c in list) c['id'] as int]);
    refreshAllGlobalData();
    AppToast.success('Diurutkan', 'Yang paling sering dipakai kini di atas');
  }

  Future<void> setArchived(Map<String, dynamic> cat, bool value) async {
    await DatabaseHelper.instance
        .updateCategory(cat['id'] as int, {'is_archived': value ? 1 : 0});
    await loadCategories();
    refreshAllGlobalData();
    AppToast.success(value ? 'Diarsipkan' : 'Dipulihkan',
        '${cat['name']} ${value ? 'disembunyikan dari Catat' : 'aktif kembali'}');
  }

  /// FR-021: a category with transactions offers Arsipkan first.
  Future<void> deleteCategory(Map<String, dynamic> cat) async {
    final id = cat['id'] as int;
    final label = cat['name'] as String;
    final count = counts[id] ?? 0;
    final db = DatabaseHelper.instance;
    if (count == 0) {
      final ok = await AppDialog.confirm(
        icon: LucideIcons.trash2,
        title: 'Hapus $label?',
        message: 'Kategori ini belum dipakai. Anggaran dan transaksi '
            'berulangnya ikut terhapus.',
        confirmLabel: 'Hapus kategori',
        destructive: true,
      );
      if (!ok) return;
      await db.deleteCategory(id);
    } else {
      final choice = await AppDialog.choose(
        icon: LucideIcons.archive,
        title: 'Hapus $label?',
        message: 'Kategori ini dipakai di $count transaksi. Arsipkan agar '
            'riwayat tetap utuh dan kategori tidak muncul di Catat.',
        info: const DialogInfo(
            'Menghapus juga menghapus semua transaksinya dan mengembalikan '
            'saldo rekening.',
            warning: true),
        safeLabel: 'Arsipkan',
        dangerLabel: 'Hapus beserta $count transaksi',
      );
      if (choice == DialogChoice.cancel) return;
      if (choice == DialogChoice.safe) {
        await setArchived(cat, true);
        _closeForm();
        return;
      }
      await db.deleteCategoryWithTransactions(id);
    }
    await loadCategories();
    refreshAllGlobalData();
    _closeForm();
    AppToast.success('Dihapus', '$label telah dihapus');
  }

  void _closeForm() {
    if (Get.currentRoute == addCategoryRoute) Get.back();
  }

  // ─── Form ────────────────────────────────────────────────────────────────

  void openNew() {
    resetForm(type: currentType.value);
    Get.toNamed(addCategoryRoute);
  }

  void openEdit(Map<String, dynamic> cat) {
    editingId.value = cat['id'] as int;
    name.value = cat['name'] as String;
    formType.value = cat['type'] as String;
    iconKey.value = IconRegistry.contains(cat['icon_key'] as String?)
        ? cat['icon_key'] as String
        : IconRegistry.legacyToKey(
            iconPath: cat['icon_path'] as String?,
            iconCode: cat['icon_code'] as int?);
    colorVal.value = nearestPaletteValue(
        cat['color_val'] as int? ?? categoryPaletteValues.last);
    formVersion.value++;
    Get.toNamed(addCategoryRoute);
  }

  void resetForm({String type = 'pengeluaran'}) {
    editingId.value = null;
    name.value = '';
    formType.value = type;
    iconKey.value = type == 'pemasukan' ? 'gaji' : 'makan';
    if (!IconRegistry.contains(iconKey.value)) {
      iconKey.value = IconRegistry.fallbackKey;
    }
    colorVal.value = categoryPaletteValues[
        (expense.length + income.length) % categoryPaletteValues.length];
    formVersion.value++;
  }

  String? get nameError {
    final n = name.value.trim();
    if (n.isEmpty) return null;
    final list = formType.value == 'pengeluaran' ? expense : income;
    final taken = list.any((c) =>
        c['id'] != editingId.value &&
        (c['name'] as String).toLowerCase() == n.toLowerCase());
    return taken ? 'Nama ini sudah dipakai' : null;
  }

  bool get canSave => name.value.trim().isNotEmpty && nameError == null;

  Future<void> saveCategory() async {
    if (isWorking.value || !canSave) return;
    isWorking.value = true;
    try {
      final data = {
        'name': name.value.trim(),
        'type': formType.value,
        'icon_key': iconKey.value,
        'color_val': colorVal.value,
      };
      final db = DatabaseHelper.instance;
      final editing = isEditMode;
      if (editing) {
        await db.updateCategory(editingId.value!, data);
      } else {
        final list = formType.value == 'pengeluaran' ? expense : income;
        await db.insertCategory({...data, 'sort_order': list.length});
      }
      // Refresh before closing: when the form was opened on its own (from
      // Catat or Anggaran) this controller is deleted once the pop finishes,
      // and a reload landing after that threw — skipping the global refresh.
      await loadCategories();
      refreshAllGlobalData();
      Get.back();
      AppToast.success(editing ? 'Kategori diperbarui' : 'Kategori dibuat',
          '${data['name']} siap dipakai');
    } catch (_) {
      AppToast.error('Gagal', 'Kategori tidak dapat disimpan');
    } finally {
      isWorking.value = false;
    }
  }
}
