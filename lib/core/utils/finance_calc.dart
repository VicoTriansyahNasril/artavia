import 'package:artavia/core/utils/date_format.dart';

/// Net worth from account rows. Accounts flagged `is_excluded` are ignored
/// everywhere so every screen shows the same number (FR-013).
class NetWorth {
  final int asset;
  final int liability;

  const NetWorth(this.asset, this.liability);

  int get net => asset - liability;
}

/// Excluded ("tidak dihitung") and archived accounts never count toward net
/// worth, so every screen shows the same number.
bool isExcludedAccount(Map<String, dynamic> account) {
  final value = account['is_excluded'] ?? account['exclude_from_total'];
  return value == true || value == 1 || account['is_archived'] == 1;
}

/// Rekening groups (board order) for an account type.
const accountGroups = [
  'Kas & bank',
  'E-wallet',
  'Investasi',
  'Kartu kredit & utang',
  'Lainnya',
];

String accountGroup(String? type) => switch (type) {
      'Kas Tunai' || 'Bank' || 'Tabungan' || 'Kas Pribadi' => 'Kas & bank',
      'Dompet Digital' => 'E-wallet',
      'Investasi' || 'Investasi Aset' => 'Investasi',
      'Kartu Kredit' || 'Pinjaman' => 'Kartu kredit & utang',
      _ => 'Lainnya',
    };

NetWorth computeNetWorth(Iterable<Map<String, dynamic>> accounts) {
  var asset = 0;
  var liability = 0;
  for (final acc in accounts) {
    if (isExcludedAccount(acc)) continue;
    final balance = acc['balance'] as int? ?? 0;
    if (balance >= 0) {
      asset += balance;
    } else {
      liability -= balance;
    }
  }
  return NetWorth(asset, liability);
}

// ─── Trend ────────────────────────────────────────────────────────────────────

enum TrendMode { week, month, year }

class TrendPoint {
  final int x;
  final String label;
  final int amount;

  const TrendPoint(this.x, this.label, this.amount);
}

/// Expense totals bucketed for the trend chart over `start <= date < end`:
/// week → one point per day (7), month → one per day of the period,
/// year → one per calendar month (12). Buckets with no spending are 0.
List<TrendPoint> buildTrend(
  Iterable<Map<String, dynamic>> transactions,
  TrendMode mode,
  DateTime start,
  DateTime end,
) {
  final buckets = _emptyBuckets(mode, start, end);
  for (final t in transactions) {
    if (t['type'] != 'pengeluaran') continue;
    final date = DateTime.parse(t['date'] as String);
    if (date.isBefore(start) || !date.isBefore(end)) continue;
    final index = mode == TrendMode.year
        ? date.month - 1
        : DateTime(date.year, date.month, date.day)
            .difference(DateTime(start.year, start.month, start.day))
            .inDays;
    if (index < 0 || index >= buckets.length) continue;
    final b = buckets[index];
    buckets[index] = TrendPoint(b.x, b.label, b.amount + (t['amount'] as int));
  }
  return buckets;
}

List<TrendPoint> _emptyBuckets(TrendMode mode, DateTime start, DateTime end) {
  if (mode == TrendMode.year) {
    return [
      for (var m = 1; m <= 12; m++) TrendPoint(m - 1, IdNames.monthShort(m), 0)
    ];
  }
  final days = DateTime(end.year, end.month, end.day)
      .difference(DateTime(start.year, start.month, start.day))
      .inDays;
  return [
    for (var i = 0; i < days; i++)
      _dayPoint(mode, i, DateTime(start.year, start.month, start.day + i)),
  ];
}

TrendPoint _dayPoint(TrendMode mode, int index, DateTime day) {
  final label = mode == TrendMode.week ? IdNames.dayShort(day) : '${day.day}';
  return TrendPoint(index, label, 0);
}

/// Monday 00:00 of the week containing [date].
DateTime startOfWeek(DateTime date) =>
    DateTime(date.year, date.month, date.day - (date.weekday - 1));

// ─── Search ───────────────────────────────────────────────────────────────────

/// Search chip filter: Semua, Pengeluaran, Pemasukan, Transfer (FR-010).
bool matchesTypeFilter(String type, String filter) {
  switch (filter) {
    case 'Pengeluaran':
      return type == 'pengeluaran';
    case 'Pemasukan':
      return type == 'pemasukan';
    case 'Transfer':
      return type == 'transfer';
    default:
      return true;
  }
}

// ─── Budget ───────────────────────────────────────────────────────────────────

/// Expense total per category id over the given transactions.
Map<int, int> expenseByCategoryId(Iterable<Map<String, dynamic>> transactions) {
  final result = <int, int>{};
  for (final t in transactions) {
    final categoryId = t['category_id'] as int?;
    if (t['type'] != 'pengeluaran' || categoryId == null) continue;
    result[categoryId] = (result[categoryId] ?? 0) + (t['amount'] as int);
  }
  return result;
}

class BudgetSummary {
  final int total;
  final int used;
  final int overCount;

  const BudgetSummary(this.total, this.used, this.overCount);

  double get ratio => total == 0 ? 0 : used / total;
}

/// Totals for budget rows (`category_id`, `budget_amount`) given usage.
BudgetSummary summarizeBudget(
  Iterable<Map<String, dynamic>> budgets,
  Map<int, int> usedByCategory,
) {
  var total = 0;
  var used = 0;
  var over = 0;
  for (final b in budgets) {
    final limit = b['budget_amount'] as int;
    final spent = usedByCategory[b['category_id'] as int?] ?? 0;
    total += limit;
    used += spent;
    if (spent > limit) over++;
  }
  return BudgetSummary(total, used, over);
}

/// Catat category grid (FR-009): most-used first, then manual `sort_order`,
/// then id. Archived categories are skipped. [usage] maps category id → count.
List<Map<String, dynamic>> rankCategories(
  Iterable<Map<String, dynamic>> categories,
  Map<int, int> usage, {
  int? limit,
}) {
  final list = categories.where((c) => (c['is_archived'] ?? 0) != 1).toList()
    ..sort((a, b) {
      final byUse = (usage[b['id']] ?? 0).compareTo(usage[a['id']] ?? 0);
      if (byUse != 0) return byUse;
      final byOrder = ((a['sort_order'] as int?) ?? 0)
          .compareTo((b['sort_order'] as int?) ?? 0);
      if (byOrder != 0) return byOrder;
      return (a['id'] as int).compareTo(b['id'] as int);
    });
  return limit == null ? list : list.take(limit).toList();
}

// ─── Insight ──────────────────────────────────────────────────────────────────

/// Expense this week (Mon → today) vs the same span last week (FR-014).
class WeeklyInsight {
  final int thisWeek;
  final int lastWeek;

  const WeeklyInsight(this.thisWeek, this.lastWeek);

  /// Change in percent, or null when last week had nothing to compare with.
  int? get percent =>
      lastWeek == 0 ? null : ((thisWeek - lastWeek) * 100 / lastWeek).round();

  bool get isLower => (percent ?? 0) < 0;

  String get text {
    final p = percent;
    if (thisWeek == 0 && lastWeek == 0) {
      return 'Belum ada pengeluaran minggu ini.';
    }
    if (p == null) return 'Belum ada pembanding dari minggu lalu.';
    if (p == 0) return 'Pengeluaran minggu ini sama dengan minggu lalu.';
    return p < 0
        ? 'Pengeluaran minggu ini ${-p}% lebih hemat dari minggu lalu.'
        : 'Pengeluaran minggu ini $p% lebih tinggi dari minggu lalu.';
  }
}

WeeklyInsight weeklyInsight(
    Iterable<Map<String, dynamic>> transactions, DateTime now) {
  final start = startOfWeek(now);
  final end = DateTime(now.year, now.month, now.day + 1);
  final lastStart = start.subtract(const Duration(days: 7));
  final lastEnd = end.subtract(const Duration(days: 7));
  var thisWeek = 0, lastWeek = 0;
  for (final t in transactions) {
    if (t['type'] != 'pengeluaran') continue;
    final d = DateTime.parse(t['date'] as String);
    final amount = t['amount'] as int;
    if (!d.isBefore(start) && d.isBefore(end)) thisWeek += amount;
    if (!d.isBefore(lastStart) && d.isBefore(lastEnd)) lastWeek += amount;
  }
  return WeeklyInsight(thisWeek, lastWeek);
}

// ─── Budget status ────────────────────────────────────────────────────────────

enum BudgetLevel { safe, near, over }

/// >= 80 % = near ("Perlu perhatian", yellow); above the limit = over (red).
BudgetLevel budgetStatus(int used, int limit) {
  if (limit <= 0) return used > 0 ? BudgetLevel.over : BudgetLevel.safe;
  if (used > limit) return BudgetLevel.over;
  if (used * 10 >= limit * 8) return BudgetLevel.near;
  return BudgetLevel.safe;
}

/// "Aman dibelanjakan ± Rp X per hari" — 0 when nothing is left.
int safeDailySpend(int remaining, int daysLeft) =>
    remaining <= 0 || daysLeft <= 0 ? 0 : remaining ~/ daysLeft;

/// Suggested monthly limit per category: average monthly expense over the
/// months that have data (max [months]), rounded up to 50.000.
Map<int, int> budgetSuggestions(
  Iterable<Map<String, dynamic>> transactions, {
  int months = 3,
}) {
  final totals = <int, int>{};
  final monthKeys = <String>{};
  for (final t in transactions) {
    final cat = t['category_id'] as int?;
    if (t['type'] != 'pengeluaran' || cat == null) continue;
    final d = DateTime.parse(t['date'] as String);
    monthKeys.add('${d.year}-${d.month}');
    totals[cat] = (totals[cat] ?? 0) + (t['amount'] as int);
  }
  if (monthKeys.isEmpty) return {};
  final n = monthKeys.length.clamp(1, months);
  const step = 50000;
  return {
    for (final e in totals.entries)
      if (e.value > 0) e.key: ((e.value / n) / step).ceil() * step,
  };
}
