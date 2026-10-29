import 'package:get/get.dart';
import 'package:artavia/model/transaction_model.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/core/utils/finance_calc.dart';
import 'package:artavia/core/utils/text_match.dart';

/// Cari (FR-023): name, note, category and account; filters for period,
/// type and account; recent searches; spelling suggestion when nothing
/// matches.
class SearchController extends GetxController {
  static const typeFilters = ['Semua', 'Pengeluaran', 'Pemasukan', 'Transfer'];

  final searchQuery = ''.obs;
  final filterType = 'Semua'.obs;

  /// true = only the active period; false = all time.
  final thisPeriodOnly = true.obs;
  final accountId = RxnInt();

  final results = <TransactionModel>[].obs;
  final isLoading = false.obs;
  final suggestion = RxnString();

  final accounts = <Map<String, dynamic>>[].obs;
  final categoryNames = <String>[].obs;
  final recent = <String>[].obs;

  Period get period => PeriodService.to.active.value;
  bool get hasQuery => searchQuery.value.trim().isNotEmpty;

  /// Net of the results: income − expense (transfers excluded).
  int get total => results.fold(0, (s, t) {
        if (t.type == 'transfer') return s;
        return s + (t.amount ?? 0);
      });

  /// Results grouped by calendar day, newest first.
  Map<DateTime, List<TransactionModel>> get byDay {
    final map = <DateTime, List<TransactionModel>>{};
    for (final t in results) {
      final d = t.date!;
      map.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(t);
    }
    return map;
  }

  @override
  void onInit() {
    super.onInit();
    recent.value = SettingsService.to.recentSearches;
    debounce(searchQuery, (_) => doSearch(remember: true),
        time: const Duration(milliseconds: 300));
    everAll([filterType, thisPeriodOnly, accountId], (_) => doSearch());
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    final db = DatabaseHelper.instance;
    accounts.value = (await db.readAllAccounts())
        .where((a) => a['is_archived'] != 1)
        .toList();
    final usage = await db.categoryUsage('pengeluaran');
    final cats = await db.readAllCategories();
    categoryNames.value = rankCategories(
            cats.where((c) => c['type'] == 'pengeluaran'), usage,
            limit: 8)
        .map((c) => c['name'] as String)
        .toList();
  }

  void setQuery(String q) => searchQuery.value = q;

  void useRecent(String q) {
    searchQuery.value = q;
    doSearch(remember: true);
  }

  Future<void> clearRecent() async {
    await SettingsService.to.clearRecentSearches();
    recent.clear();
  }

  void searchAllPeriods() => thisPeriodOnly.value = false;

  Future<void> doSearch({bool remember = false}) async {
    final q = searchQuery.value.trim();
    if (q.isEmpty) {
      results.clear();
      suggestion.value = null;
      return;
    }
    isLoading.value = true;
    try {
      final rows = await DatabaseHelper.instance.searchTransactions(q);
      final p = period;
      results.value = rows
          .where(
              (r) => matchesTypeFilter(r['type'] as String, filterType.value))
          .where((r) =>
              accountId.value == null ||
              r['account_id'] == accountId.value ||
              r['destination_account_id'] == accountId.value)
          .where((r) {
            if (!thisPeriodOnly.value) return true;
            final d = DateTime.parse(r['date'] as String);
            return !d.isBefore(p.start) && d.isBefore(p.end);
          })
          .map(TransactionModel.fromDbRow)
          .toList();

      suggestion.value = results.isEmpty && rows.isEmpty
          ? suggestSpelling(q, await _vocabulary())
          : null;
      if (remember && results.isNotEmpty) {
        await SettingsService.to.addRecentSearch(q);
        recent.value = SettingsService.to.recentSearches;
      }
    } catch (e) {
      Get.log('Search error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Set<String>> _vocabulary() async {
    final db = DatabaseHelper.instance;
    final words = <String>{
      for (final c in await db.readAllCategories())
        ...wordsOf(c['name'] as String),
      for (final a in accounts) ...wordsOf(a['name'] as String),
    };
    for (final t in await db.readAllTransactions()) {
      words.addAll(wordsOf(t['note'] as String? ?? ''));
    }
    return words;
  }
}
