import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/utils/data_refresh.dart';
import 'package:artavia/core/utils/finance_calc.dart';
import 'package:artavia/widgets/components/app_feedback.dart';

/// One budget row with its usage this period.
class BudgetItem {
  final int id;
  final int categoryId;
  final String name;
  final int limit;
  final int used;
  final int? colorVal;
  final String? iconKey;
  final String? iconPath;
  final int? iconCode;

  const BudgetItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.limit,
    required this.used,
    this.colorVal,
    this.iconKey,
    this.iconPath,
    this.iconCode,
  });

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
/// last 3 months when nothing is budgeted yet.
class BudgetController extends GetxController {
  final isLoading = false.obs;
  final isWorking = false.obs;
  final items = <BudgetItem>[].obs;
  final suggestions = <BudgetSuggestion>[].obs;

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

  List<Map<String, dynamic>> get unbudgeted => categories
      .where((c) => !items.any((i) => i.categoryId == c['id']))
      .toList();

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
            categoryId: b['category_id'] as int,
            name: b['categoryName'] as String? ?? '',
            limit: b['budget_amount'] as int,
            used: used[b['category_id']] ?? 0,
            colorVal: b['categoryColorVal'] as int?,
            iconKey: b['categoryIconKey'] as String?,
            iconPath: b['categoryIconPath'] as String?,
            iconCode: b['categoryIconCode'] as int?,
          ),
      ];

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

  Future<void> save(int categoryId, int amount, {bool close = true}) async {
    if (amount <= 0 || isWorking.value) return;
    isWorking.value = true;
    try {
      final p = period;
      await DatabaseHelper.instance.upsertBudget(
          categoryId: categoryId, amount: amount, month: p.month, year: p.year);
      if (close) Get.back();
      refreshAllGlobalData();
      AppToast.success('Anggaran disimpan', 'Berlaku untuk ${p.longLabel}');
    } finally {
      isWorking.value = false;
    }
  }

  /// "Pakai" on a suggestion.
  Future<void> useSuggestion(BudgetSuggestion s) =>
      save(s.category['id'] as int, s.amount, close: false);

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
