import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/services/budget_import.dart';
import 'package:artavia/core/services/import_service.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/utils/data_refresh.dart';
import 'package:artavia/core/utils/finance_calc.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/widgets/components/app_feedback.dart';

/// One named budget with its categories and usage this period.
class BudgetItem {
  final int id;
  final String name;
  final int limit;
  final int used;

  /// Category rows covered by this budget (at least one).
  final List<Map<String, dynamic>> categories;

  /// Icon/color chosen for the budget itself; null = follow categories.
  final String? ownIconKey;
  final int? ownColorVal;

  const BudgetItem({
    required this.id,
    required this.name,
    required this.limit,
    required this.used,
    required this.categories,
    this.ownIconKey,
    this.ownColorVal,
  });

  Set<int> get categoryIds => {for (final c in categories) c['id'] as int};

  /// Own icon, else the only category's, else a tag (multi-category).
  Map<String, dynamic> get _first => categories.first;
  bool get isSingle => categories.length == 1;
  bool get _catIcon => ownIconKey == null && isSingle;
  String? get iconKey =>
      ownIconKey ?? (isSingle ? _first['icon_key'] as String? : 'label');
  String? get iconPath => _catIcon ? _first['icon_path'] as String? : null;
  int? get iconCode => _catIcon ? _first['icon_code'] as int? : null;
  int? get colorVal => ownColorVal ?? _first['color_val'] as int?;

  /// Category names under the title, unless the name already says it.
  String? get categoryLabel {
    final names = [for (final c in categories) c['name'] as String];
    if (isSingle && names.single == name) return null;
    return names.join(', ');
  }

  BudgetLevel get level => budgetStatus(used, limit);
  int get left => limit - used;
  double get ratio => limit == 0 ? 1 : used / limit;
}

/// Suggested limit for a category without a budget (board "Saran").
class BudgetSuggestion {
  final Map<String, dynamic> category;
  final int amount;
  const BudgetSuggestion(this.category, this.amount);
}

/// Anggaran (FR-022): hero with remaining + safe daily spend, "Perlu
/// perhatian" (≥ 80 % / over) and "Aman" groups, and suggestions from the
/// last 3 months when nothing is budgeted yet. A budget has its own name
/// and covers one or more expense categories; a category counts toward at
/// most one budget per period.
class BudgetController extends GetxController {
  static const maxName = 30;

  final isLoading = false.obs;
  final isWorking = false.obs;
  final items = <BudgetItem>[].obs;
  final suggestions = <BudgetSuggestion>[].obs;

  /// Budgets in the previous period (offered for copying when this one is
  /// empty).
  final previousCount = 0.obs;

  /// Expense categories (non-archived) for the add sheet.
  final categories = <Map<String, dynamic>>[].obs;

  PeriodService get _period => PeriodService.to;
  Period get period => _period.active.value;

  int get totalLimit => items.fold(0, (s, i) => s + i.limit);
  int get totalUsed => items.fold(0, (s, i) => s + i.used);
  int get remaining => totalLimit - totalUsed;

  List<BudgetItem> get attention =>
      items.where((i) => i.level != BudgetLevel.safe).toList()
        ..sort((a, b) => b.ratio.compareTo(a.ratio));
  List<BudgetItem> get safe =>
      items.where((i) => i.level == BudgetLevel.safe).toList();

  /// Days left in the active period, counting today.
  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final p = period;
    if (!today.isBefore(p.end)) return 0;
    final from = today.isBefore(p.start) ? p.start : today;
    return p.end.difference(from).inDays;
  }

  int get safeDaily => safeDailySpend(remaining, daysLeft);

  /// Expense categories free for [item] (all when null = new budget):
  /// not held by another budget, plus [item]'s own (even if archived).
  List<Map<String, dynamic>> availableFor(BudgetItem? item) {
    final taken = {
      for (final i in items)
        if (i.id != item?.id) ...i.categoryIds,
    };
    final own = item?.categories ?? const [];
    return [
      ...own.where((c) => !categories.any((x) => x['id'] == c['id'])),
      ...categories.where((c) => !taken.contains(c['id'])),
    ];
  }

  List<Map<String, dynamic>> get unbudgeted => availableFor(null);

  /// Budget names are unique (case-insensitive) within a period.
  bool nameTaken(String name, {int? exceptId}) {
    final n = name.trim().toLowerCase();
    return n.isNotEmpty &&
        items.any((i) => i.id != exceptId && i.name.toLowerCase() == n);
  }

  /// Category row by id (active categories and those held by budgets).
  Map<String, dynamic>? categoryById(int id) => [
        ...categories,
        for (final i in items) ...i.categories,
      ].where((c) => c['id'] == id).firstOrNull;

  /// Name saved when the field is left empty: the category names.
  String defaultName(Iterable<int> categoryIds) => <String>{
        for (final c in [...categories, for (final i in items) ...i.categories])
          if (categoryIds.contains(c['id'])) c['name'] as String,
      }.join(', ');

  @override
  void onInit() {
    super.onInit();
    ever(_period.active, (_) => loadData());
    loadData();
  }

  void shift(int months) => _period.shift(months);

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      final p = period;
      final db = DatabaseHelper.instance;
      final budgets = await db.readBudgetsByMonth(p.year, p.month);
      final rows = await db.readTransactionsByRange(p.start, p.end);
      final cats = await db.readAllCategories();
      categories.value = cats
          .where((c) => c['type'] == 'pengeluaran' && c['is_archived'] != 1)
          .toList();

      final used = expenseByCategoryId(rows);
      items.value = [
        for (final b in budgets)
          BudgetItem(
            id: b['id'] as int,
            name: b['name'] as String,
            limit: b['budget_amount'] as int,
            used: budgetUsed(b, used),
            categories: (b['categories'] as List).cast(),
            ownIconKey: b['icon_key'] as String?,
            ownColorVal: b['color_val'] as int?,
          ),
      ];
      final prev = p.shift(-1);
      previousCount.value = items.isEmpty
          ? (await db.readBudgetsByMonth(prev.year, prev.month)).length
          : 0;

      suggestions.clear();
      if (items.isEmpty) {
        final history =
            await db.readTransactionsByRange(p.shift(-3).start, p.start);
        final s = budgetSuggestions(history);
        suggestions.value = [
          for (final c in categories)
            if (s[c['id']] != null) BudgetSuggestion(c, s[c['id']]!),
        ]..sort((a, b) => b.amount.compareTo(a.amount));
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Saves a new ([item] null) or edited budget from the sheet.
  Future<void> save({
    BudgetItem? item,
    required String name,
    required Set<int> categoryIds,
    required int amount,
    String? iconKey,
    int? colorVal,
  }) async {
    if (amount <= 0 || categoryIds.isEmpty || isWorking.value) return;
    if (nameTaken(name, exceptId: item?.id)) return;
    isWorking.value = true;
    try {
      final p = period;
      final label =
          name.trim().isEmpty ? defaultName(categoryIds) : name.trim();
      await DatabaseHelper.instance.saveBudget(
          id: item?.id,
          name: label,
          amount: amount,
          categoryIds: categoryIds,
          month: p.month,
          year: p.year,
          iconKey: iconKey,
          colorVal: colorVal);
      refreshAllGlobalData();
      Get.back();
      AppToast.success('Anggaran disimpan', '$label · ${p.longLabel}');
    } catch (_) {
      AppToast.error('Gagal', 'Anggaran tidak dapat disimpan');
    } finally {
      isWorking.value = false;
    }
  }

  /// Opens "Kategori baru" (expense) over the sheet and returns the ids of
  /// the categories created there, already loaded into [categories].
  Future<Set<int>> addCategory() async {
    final before = {for (final c in categories) c['id'] as int};
    await Get.toNamed(addCategoryRoute, arguments: {'type': 'pengeluaran'});
    await loadData();
    return {
      for (final c in categories)
        if (!before.contains(c['id'])) c['id'] as int,
    };
  }

  /// "Pakai" on a suggestion: a one-category budget named after it.
  Future<void> useSuggestion(BudgetSuggestion s) async {
    final p = period;
    await DatabaseHelper.instance.upsertBudget(
        categoryId: s.category['id'] as int,
        amount: s.amount,
        month: p.month,
        year: p.year);
    refreshAllGlobalData();
    AppToast.success('Anggaran disimpan', 'Berlaku untuk ${p.longLabel}');
  }

  /// Copies the previous period's budgets into the active one.
  Future<void> copyFromPrevious() => _copy(from: period.shift(-1), to: period);

  /// Copies the active period's budgets into the next one.
  Future<void> copyToNext() => _copy(from: period, to: period.shift(1));

  Future<void> _copy({required Period from, required Period to}) async {
    if (isWorking.value) return;
    isWorking.value = true;
    try {
      final n = await DatabaseHelper.instance.copyBudgets(
          fromYear: from.year,
          fromMonth: from.month,
          toYear: to.year,
          toMonth: to.month);
      refreshAllGlobalData();
      if (n == 0) {
        AppToast.info('Tidak ada yang disalin',
            'Anggaran ${from.longLabel} sudah ada di ${to.longLabel}');
      } else {
        AppToast.success(
            '$n anggaran disalin', 'Dari ${from.longLabel} ke ${to.longLabel}');
      }
    } catch (_) {
      AppToast.error('Gagal', 'Anggaran tidak dapat disalin');
    } finally {
      isWorking.value = false;
    }
  }

  /// Impor anggaran from the "Anggaran" sheet of an Ekspor file (or a CSV
  /// with the same headers), after a confirmation with the counts.
  Future<void> importFile() async {
    if (isWorking.value) return;
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'csv'],
      dialogTitle: 'Pilih file anggaran',
    );
    if (picked == null) return;
    isWorking.value = true;
    try {
      final sheet =
          BudgetImport.parseFile(picked.name, await picked.readAsBytes());
      if (sheet.rows.isEmpty) {
        AppToast.error('Tidak ada anggaran yang bisa diimpor',
            sheet.problems.isEmpty ? 'File kosong' : sheet.problems.first);
        return;
      }
      final months = {for (final r in sheet.rows) '${r.month}/${r.year}'};
      final ok = await AppDialog.confirm(
        icon: LucideIcons.fileDown,
        title: 'Impor ${sheet.rows.length} anggaran?',
        message: 'Untuk ${months.length} bulan. Anggaran dengan nama yang '
            'sama di bulan itu diperbarui; kategori yang belum ada dibuat.',
        info: sheet.problems.isEmpty
            ? null
            : DialogInfo(
                '${sheet.problems.length} baris dilewati — '
                '${sheet.problems.take(3).join('; ')}',
                warning: true),
        confirmLabel: 'Impor',
      );
      if (!ok) return;
      final r = await DatabaseHelper.instance.importBudgets(sheet.rows);
      refreshAllGlobalData();
      AppToast.success(
          'Anggaran diimpor',
          '${r.created} baru · ${r.updated} diperbarui'
              '${r.newCategories > 0 ? ' · ${r.newCategories} kategori baru' : ''}');
    } on ImportFileError catch (e) {
      AppToast.error('File tidak bisa dibaca', e.message);
    } catch (_) {
      AppToast.error('Impor gagal', 'Tidak ada anggaran yang diubah');
    } finally {
      isWorking.value = false;
    }
  }

  Future<void> useAllSuggestions() async {
    final p = period;
    for (final s in suggestions) {
      await DatabaseHelper.instance.upsertBudget(
          categoryId: s.category['id'] as int,
          amount: s.amount,
          month: p.month,
          year: p.year);
    }
    refreshAllGlobalData();
    AppToast.success('Anggaran dibuat', '${suggestions.length} kategori');
  }

  Future<void> delete(BudgetItem item) async {
    final ok = await AppDialog.confirm(
      title: 'Hapus anggaran ${item.name}?',
      message: 'Batas untuk ${period.longLabel} akan dihapus. '
          'Transaksinya tidak berubah.',
      confirmLabel: 'Hapus anggaran',
      destructive: true,
    );
    if (!ok) return;
    await DatabaseHelper.instance.deleteBudget(item.id);
    Get.back();
    refreshAllGlobalData();
  }
}
