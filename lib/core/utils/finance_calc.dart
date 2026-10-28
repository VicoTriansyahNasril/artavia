import 'package:artavia/core/utils/date_format.dart';

/// Net worth from account rows. Accounts flagged `is_excluded` are ignored
/// everywhere so every screen shows the same number (FR-013).
class NetWorth {
  final int asset;
  final int liability;

  const NetWorth(this.asset, this.liability);

  int get net => asset - liability;
}

bool isExcludedAccount(Map<String, dynamic> account) {
  final value = account['is_excluded'] ?? account['exclude_from_total'];
  return value == true || value == 1;
}

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
