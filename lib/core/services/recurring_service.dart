import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/database/transaction_store.dart';
import 'package:artavia/core/models/recurring_rule.dart';

/// Upper bound per rule per run, so a very old start date can't freeze startup.
const maxOccurrencesPerRun = 400;

/// Occurrences of [rule] that are due (on or before [today]) and not yet
/// generated. Monthly rules keep the start day, clamped to short months.
List<DateTime> dueDates(RecurringRule rule, DateTime today) {
  final limit = DateTime(today.year, today.month, today.day);
  final result = <DateTime>[];
  var index = 0;
  var next = _occurrence(rule, index);
  final last = rule.lastRunDate;
  if (last != null) {
    final lastDay = DateTime(last.year, last.month, last.day);
    while (!next.isAfter(lastDay)) {
      next = _occurrence(rule, ++index);
    }
  }
  while (!next.isAfter(limit) && result.length < maxOccurrencesPerRun) {
    result.add(next);
    next = _occurrence(rule, ++index);
  }
  return result;
}

/// The next occurrence that has not been generated yet.
DateTime nextOccurrence(RecurringRule rule) {
  final last = rule.lastRunDate;
  var index = 0;
  var next = _occurrence(rule, index);
  while (last != null && !next.isAfter(last)) {
    next = _occurrence(rule, ++index);
  }
  return next;
}

/// The [n]-th occurrence counted from the start date (n = 0 is the start).
DateTime _occurrence(RecurringRule rule, int n) {
  final s = rule.startDate;
  switch (rule.frequency) {
    case RecurringFrequency.daily:
      return DateTime(s.year, s.month, s.day + n);
    case RecurringFrequency.weekly:
      return DateTime(s.year, s.month, s.day + 7 * n);
    case RecurringFrequency.monthly:
      final lastDayOfMonth = DateTime(s.year, s.month + n + 1, 0).day;
      final day = s.day > lastDayOfMonth ? lastDayOfMonth : s.day;
      return DateTime(s.year, s.month + n, day);
  }
}

/// Generates due transactions for every active rule (FR-031b).
class RecurringService extends GetxService {
  static RecurringService get to => Get.find();

  /// Returns how many transactions were created.
  Future<int> runDue({DateTime? now}) async {
    final today = now ?? DateTime.now();
    var created = 0;
    try {
      final rows = await DatabaseHelper.instance.readRecurringRules();
      for (final rule in rows.map(RecurringRule.fromRow)) {
        if (!rule.isActive || rule.id == null) continue;
        final dates = dueDates(rule, today);
        if (dates.isEmpty) continue;
        await DatabaseHelper.instance.insertRecurringOccurrences(
          rule.id!,
          [for (final d in dates) _transactionRow(rule, d)],
          RecurringRule.dateOnly(dates.last),
        );
        created += dates.length;
      }
    } catch (e) {
      Get.log('Recurring run failed: $e');
    }
    return created;
  }

  Map<String, dynamic> _transactionRow(RecurringRule rule, DateTime date) => {
        'type': rule.type,
        'amount': rule.amount,
        'category_id': rule.categoryId,
        'account_id': rule.accountId,
        'note': rule.note,
        'date': DateTime(date.year, date.month, date.day, 8).toIso8601String(),
      };
}
