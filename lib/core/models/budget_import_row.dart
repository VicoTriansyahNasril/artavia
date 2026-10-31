/// One budget read from an "Anggaran" sheet, ready to write.
class BudgetImportRow {
  final int year;
  final int month;
  final String name;

  /// Expense category names (matched case-insensitively, created if new).
  final List<String> categories;
  final int amount;
  final String? iconKey;
  final int? colorVal;

  const BudgetImportRow({
    required this.year,
    required this.month,
    required this.name,
    required this.categories,
    required this.amount,
    this.iconKey,
    this.colorVal,
  });
}

/// What [DatabaseHelper.importBudgets] wrote.
class BudgetImportResult {
  final int created;
  final int updated;
  final int newCategories;

  const BudgetImportResult(this.created, this.updated, this.newCategories);
}
