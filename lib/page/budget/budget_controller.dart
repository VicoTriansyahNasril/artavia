import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/finance_calc.dart';
import 'package:artavia/core/utils/data_refresh.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/components/app_feedback.dart';

class BudgetController extends GetxController {
  final isLoading = false.obs;

  // Budget items: {id, category_id, category, budget_amount, used, color, icon_code, icon_path}
  final budgetItems = <Map<String, dynamic>>[].obs;

  int get totalBudget =>
      budgetItems.fold(0, (s, i) => s + (i['budget_amount'] as int));
  int get totalUsed => budgetItems.fold(0, (s, i) => s + (i['used'] as int));

  /// Expense categories available for a new budget.
  final availableCategories = <Map<String, dynamic>>[].obs;

  final RxBool isWorking = false.obs;

  PeriodService get _period => PeriodService.to;

  /// Shared with Riwayat and Grafik (FR-021).
  String get monthLabel => _period.active.value.label;

  @override
  void onInit() {
    super.onInit();
    ever(_period.active, (_) => loadData());
    loadData();
  }

  void prevMonth() => _period.shift(-1);

  void nextMonth() => _period.shift(1);

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      final p = _period.active.value;
      final db = DatabaseHelper.instance;
      final budgets = await db.readBudgetsByMonth(p.year, p.month);
      final transactions = await db.readTransactionsByRange(p.start, p.end);
      final cats = await db.readAllCategories();
      availableCategories.value =
          cats.where((c) => c['type'] == 'pengeluaran').toList();

      final used = expenseByCategoryId(transactions);
      budgetItems.value = [
        for (var i = 0; i < budgets.length; i++)
          {
            'id': budgets[i]['id'],
            'category_id': budgets[i]['category_id'] as int?,
            'category': budgets[i]['categoryName'] as String? ?? '',
            'budget_amount': budgets[i]['budget_amount'] as int,
            'used': used[budgets[i]['category_id']] ?? 0,
            'color': budgets[i]['categoryColorVal'] as int? ??
                paletteColorAt(i).toARGB32(),
            'icon_code': budgets[i]['categoryIconCode'] as int?,
            'icon_path': budgets[i]['categoryIconPath'] as String?,
          },
      ];
    } finally {
      isLoading.value = false;
    }
  }

  void showAddBudgetDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    int? categoryId;
    final amountCtrl = TextEditingController();

    _showBudgetDialog(
      title: 'Tambah Anggaran',
      formKey: formKey,
      amountCtrl: amountCtrl,
      categoryField: DropdownButtonFormField<int>(
        dropdownColor: colorSurface,
        decoration: const InputDecoration(labelText: 'Kategori'),
        items: availableCategories
            .map((c) => DropdownMenuItem<int>(
                  value: c['id'] as int,
                  child: Text(c['name'] as String),
                ))
            .toList(),
        validator: (v) => v == null ? 'Pilih kategori' : null,
        onChanged: (v) => categoryId = v,
      ),
      onSave: (amount) => _save(categoryId!, amount),
    );
  }

  void showEditBudgetDialog(BuildContext context, Map<String, dynamic> item) {
    final amountCtrl = TextEditingController(
        text: CurrencyService.to
            .formatWithoutSymbol(item['budget_amount'] as int));
    _showBudgetDialog(
      title: 'Anggaran ${item['category']}',
      formKey: GlobalKey<FormState>(),
      amountCtrl: amountCtrl,
      onSave: (amount) => _save(item['category_id'] as int, amount),
    );
  }

  void _showBudgetDialog({
    required String title,
    required GlobalKey<FormState> formKey,
    required TextEditingController amountCtrl,
    required Future<void> Function(int amount) onSave,
    Widget? categoryField,
  }) {
    int parse() =>
        int.tryParse(amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (categoryField != null) ...[
                categoryField,
                const SizedBox(height: 12)
              ],
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: colorText),
                decoration: const InputDecoration(
                    labelText: 'Batas per bulan', prefixText: 'Rp '),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(16),
                  FilteringTextInputFormatter.allow(RegExp(r'^[0-9.,]*')),
                  CurrencyInputFormatter(),
                ],
                validator: (_) => parse() <= 0 ? 'Masukkan nominal' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal', style: TextStyle(color: colorGrey)),
          ),
          FilledButton(
            onPressed: () async {
              if (isWorking.value || !formKey.currentState!.validate()) return;
              await onSave(parse());
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _save(int categoryId, int amount) async {
    isWorking.value = true;
    try {
      final p = _period.active.value;
      await DatabaseHelper.instance.upsertBudget(
        categoryId: categoryId,
        amount: amount,
        month: p.month,
        year: p.year,
      );
      Get.back();
      refreshAllGlobalData();
      AppToast.success('Berhasil', 'Anggaran disimpan');
    } finally {
      isWorking.value = false;
    }
  }

  Future<void> deleteBudget(Map<String, dynamic> item) async {
    final ok = await AppDialog.confirm(
      title: 'Hapus Anggaran',
      message: 'Hapus anggaran ${item['category']} untuk $monthLabel?',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!ok || isWorking.value) return;
    isWorking.value = true;
    try {
      await DatabaseHelper.instance.deleteBudget(item['id'] as int);
      refreshAllGlobalData();
    } finally {
      isWorking.value = false;
    }
  }
}
