/// How often a recurring rule fires.
enum RecurringFrequency {
  daily('daily', 'Harian'),
  weekly('weekly', 'Mingguan'),
  monthly('monthly', 'Bulanan');

  final String value;
  final String label;

  const RecurringFrequency(this.value, this.label);

  static RecurringFrequency parse(String? value) =>
      RecurringFrequency.values.firstWhere((f) => f.value == value,
          orElse: () => RecurringFrequency.monthly);
}

/// A rule that generates income/expense transactions (data-model.md).
class RecurringRule {
  final int? id;
  final String type;
  final int amount;
  final int categoryId;
  final int accountId;
  final String note;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime? lastRunDate;
  final bool isActive;

  // Display-only joins.
  final String? categoryName;
  final String? accountName;
  final int? categoryIconCode;
  final String? categoryIconPath;
  final int? categoryColorVal;
  final String? categoryIconKey;

  const RecurringRule({
    this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    this.note = '',
    required this.frequency,
    required this.startDate,
    this.lastRunDate,
    this.isActive = true,
    this.categoryName,
    this.accountName,
    this.categoryIconCode,
    this.categoryIconPath,
    this.categoryColorVal,
    this.categoryIconKey,
  });

  factory RecurringRule.fromRow(Map<String, dynamic> row) {
    final last = row['last_run_date'] as String?;
    return RecurringRule(
      id: row['id'] as int?,
      type: row['type'] as String,
      amount: row['amount'] as int,
      categoryId: row['category_id'] as int,
      accountId: row['account_id'] as int,
      note: row['note'] as String? ?? '',
      frequency: RecurringFrequency.parse(row['frequency'] as String?),
      startDate: DateTime.parse(row['start_date'] as String),
      lastRunDate: last == null ? null : DateTime.parse(last),
      isActive: (row['is_active'] as int? ?? 1) == 1,
      categoryName: row['categoryName'] as String?,
      accountName: row['accountName'] as String?,
      categoryIconCode: row['categoryIconCode'] as int?,
      categoryIconPath: row['categoryIconPath'] as String?,
      categoryColorVal: row['categoryColorVal'] as int?,
      categoryIconKey: row['categoryIconKey'] as String?,
    );
  }

  Map<String, dynamic> toRow() => {
        'type': type,
        'amount': amount,
        'category_id': categoryId,
        'account_id': accountId,
        'note': note,
        'frequency': frequency.value,
        'start_date': dateOnly(startDate),
        'last_run_date': lastRunDate == null ? null : dateOnly(lastRunDate!),
        'is_active': isActive ? 1 : 0,
      };

  static String dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
