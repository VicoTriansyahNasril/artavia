import 'package:get/get.dart';
import 'package:artavia/model/transaction_model.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/core/utils/data_refresh.dart';
import 'package:artavia/core/utils/date_format.dart';
import 'package:artavia/core/utils/finance_calc.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/components/app_feedback.dart';

/// One day section on Transaksi with its own totals.
class DayGroup {
  final DateTime day;
  final List<TransactionModel> items;
  final int income;
  final int expense;

  const DayGroup(this.day, this.items, this.income, this.expense);

  String get label {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'Hari ini';
    if (day == today.subtract(const Duration(days: 1))) return 'Kemarin';
    return '${IdNames.dayLong(day)}, ${day.day} ${IdNames.monthShort(day.month)}';
  }
}

/// Budget card data: overall usage plus the category closest to its limit.
class HomeBudget {
  final BudgetSummary summary;
  final String? attentionName;
  final BudgetLevel attentionLevel;

  const HomeBudget(this.summary, this.attentionName, this.attentionLevel);
}

class HomeController extends GetxController {
  static const filters = ['Semua', 'Pengeluaran', 'Pemasukan', 'Transfer'];

  /// First-account form choices (label → stored account type).
  static const starterTypes = {
    'Tunai': 'Kas Tunai',
    'Bank': 'Bank',
    'E-wallet': 'Dompet Digital',
    'Lainnya': 'Lainnya',
  };

  final isLoading = false.obs;
  final transactions = <TransactionModel>[].obs;
  final dayGroups = <DayGroup>[].obs;
  final filter = 'Semua'.obs;
  final totalPengeluaran = 0.obs;
  final totalPemasukan = 0.obs;
  final saldoTotal = 0.obs;
  final budget =
      const HomeBudget(BudgetSummary(0, 0, 0), null, BudgetLevel.safe).obs;
  final insight = const WeeklyInsight(0, 0).obs;
  final currentIndex = 0.obs;

  /// null until loaded; false shows the welcome card (FR-018).
  final hasAccounts = RxnBool();

  // First-account form
  final starterName = ''.obs;
  final starterType = 'Tunai'.obs;
  final starterBalance = 0.obs;
  final isCreating = false.obs;

  // Optional budget step after the first account: a few expense categories
  // with a monthly limit each (id → amount).
  final budgetStep = false.obs;
  final starterCategories = <Map<String, dynamic>>[].obs;
  final starterBudgets = <int, int>{}.obs;

  Period get period => PeriodService.to.active.value;

  String get greeting {
    final h = DateTime.now().hour;
    if (h >= 4 && h < 11) return 'Selamat pagi';
    if (h < 15 && h >= 11) return 'Selamat siang';
    if (h < 18 && h >= 15) return 'Selamat sore';
    return 'Selamat malam';
  }

  void changePage(int index) => currentIndex.value = index;

  void shiftPeriod(int months) => PeriodService.to.shift(months);

  void setFilter(String value) {
    filter.value = value;
    _group();
  }

  @override
  void onInit() {
    super.onInit();
    ever(PeriodService.to.active, (_) => loadData());
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      final db = DatabaseHelper.instance;
      final accounts = await db.readAllAccounts();
      hasAccounts.value = accounts.isNotEmpty;
      if (accounts.isNotEmpty && SettingsService.to.budgetStepPending) {
        await _loadBudgetStep();
      }

      final p = period;
      final rows = await db.readTransactionsByRange(p.start, p.end);
      final budgets = await db.readBudgetsByMonth(p.year, p.month);
      final now = DateTime.now();
      final recent = await db.readTransactionsByRange(
          startOfWeek(now).subtract(const Duration(days: 7)),
          DateTime(now.year, now.month, now.day + 1));

      final income = _sum(rows, 'pemasukan');
      final expense = _sum(rows, 'pengeluaran');
      totalPemasukan.value = income;
      totalPengeluaran.value = expense;
      saldoTotal.value = income - expense;
      transactions.value = rows.map(TransactionModel.fromDbRow).toList();
      insight.value = weeklyInsight(recent, now);
      budget.value = _budget(budgets, expenseByCategoryId(rows));
      _group();
    } catch (e) {
      Get.log('Error loading data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  HomeBudget _budget(
      List<Map<String, dynamic>> budgets, Map<int, int> usedByCategory) {
    String? name;
    var level = BudgetLevel.safe;
    var worst = -1.0;
    for (final b in budgets) {
      final limit = b['budget_amount'] as int;
      final used = budgetUsed(b, usedByCategory);
      final ratio = limit == 0 ? 0.0 : used / limit;
      final l = budgetStatus(used, limit);
      if (l != BudgetLevel.safe && ratio > worst) {
        worst = ratio;
        name = b['name'] as String?;
        level = l;
      }
    }
    return HomeBudget(summarizeBudget(budgets, usedByCategory), name, level);
  }

  /// Groups once here instead of in build() to keep scrolling smooth.
  void _group() {
    final groups = <DateTime, List<TransactionModel>>{};
    for (final tx in transactions) {
      if (tx.date == null || !matchesTypeFilter(tx.type ?? '', filter.value)) {
        continue;
      }
      final d = tx.date!;
      groups.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(tx);
    }
    dayGroups.value = [
      for (final e in groups.entries)
        DayGroup(
          e.key,
          e.value,
          e.value
              .where((t) => t.type == 'pemasukan')
              .fold(0, (s, t) => s + (t.amount ?? 0).abs()),
          e.value
              .where((t) => t.type == 'pengeluaran')
              .fold(0, (s, t) => s + (t.amount ?? 0).abs()),
        ),
    ];
  }

  int _sum(List<Map<String, dynamic>> rows, String type) => rows
      .where((r) => r['type'] == type)
      .fold(0, (s, r) => s + (r['amount'] as int));

  /// Creates the first account from the welcome card (FR-018).
  Future<void> createFirstAccount() async {
    final name = starterName.value.trim();
    if (name.isEmpty) {
      AppToast.warning('Nama rekening', 'Isi nama rekening dulu');
      return;
    }
    final type = starterTypes[starterType.value]!;
    isCreating.value = true;
    try {
      await DatabaseHelper.instance.insertAccount({
        'name': name,
        'type': type,
        'balance': starterBalance.value,
        'currency_code': 'IDR',
        'icon_key': IconRegistry.accountTypeKey(type),
        'color_val': categoryPaletteValues[7],
        'is_excluded': 0,
      });
      await SettingsService.to.set(SettingsService.keyBudgetStep, 'true');
      refreshAllGlobalData();
      AppToast.success('Rekening dibuat', 'Sekarang kamu bisa mulai mencatat');
    } catch (_) {
      AppToast.error('Gagal', 'Rekening tidak dapat dibuat');
    } finally {
      isCreating.value = false;
    }
  }

  /// Top expense categories (sort order) offered on the budget step.
  Future<void> _loadBudgetStep() async {
    final cats = await DatabaseHelper.instance.readAllCategories();
    starterCategories.value = cats
        .where((c) => c['type'] == 'pengeluaran' && c['is_archived'] != 1)
        .take(4)
        .toList();
    budgetStep.value = starterCategories.isNotEmpty;
  }

  /// Saves every filled limit for the active period, then ends the step.
  Future<void> saveStarterBudgets() async {
    final p = period;
    isCreating.value = true;
    try {
      for (final e in starterBudgets.entries) {
        if (e.value <= 0) continue;
        await DatabaseHelper.instance.upsertBudget(
            categoryId: e.key, amount: e.value, month: p.month, year: p.year);
      }
      await skipBudgetStep();
      AppToast.success('Anggaran disimpan', 'Berlaku untuk ${p.longLabel}');
    } catch (_) {
      AppToast.error('Gagal', 'Anggaran tidak dapat disimpan');
    } finally {
      isCreating.value = false;
    }
  }

  Future<void> skipBudgetStep() async {
    budgetStep.value = false;
    starterBudgets.clear();
    await SettingsService.to.remove(SettingsService.keyBudgetStep);
    refreshAllGlobalData();
  }
}
