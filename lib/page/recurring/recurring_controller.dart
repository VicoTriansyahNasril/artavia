import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/models/recurring_rule.dart';
import 'package:artavia/core/services/recurring_service.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/data_refresh.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/widgets/components/app_feedback.dart';

class RecurringController extends GetxController {
  final rules = <RecurringRule>[].obs;
  final isLoading = true.obs;
  final isWorking = false.obs;

  // ─── Form state ──────────────────────────────────────────────────────────
  int? editingId;
  RecurringRule? _editing;
  final type = 'pengeluaran'.obs;
  final categoryId = RxnInt();
  final accountId = RxnInt();
  final frequency = RecurringFrequency.monthly.obs;
  final startDate = DateTime.now().obs;
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final categories = <Map<String, dynamic>>[].obs;
  final accounts = <Map<String, dynamic>>[].obs;
  List<Map<String, dynamic>> _allCategories = [];

  List<Map<String, dynamic>> get categoriesForType =>
      categories.where((c) => c['type'] == type.value).toList();

  @override
  void onInit() {
    super.onInit();
    loadRules();
  }

  @override
  void onClose() {
    amountController.dispose();
    noteController.dispose();
    super.onClose();
  }

  Future<void> loadRules() async {
    isLoading.value = true;
    final rows = await DatabaseHelper.instance.readRecurringRules();
    rules.value = rows.map(RecurringRule.fromRow).toList();
    isLoading.value = false;
  }

  Future<void> openForm([RecurringRule? rule]) async {
    _allCategories = await DatabaseHelper.instance.readAllCategories();
    categories.value = _allCategories;
    accounts.value = await DatabaseHelper.instance.readAllAccounts();
    if (accounts.isEmpty) {
      AppToast.warning('Belum ada rekening', 'Buat rekening terlebih dahulu');
      return;
    }
    _fillForm(rule);
    await Get.toNamed(recurringFormRoute);
  }

  void _fillForm(RecurringRule? rule) {
    _editing = rule;
    editingId = rule?.id;
    type.value = rule?.type ?? 'pengeluaran';
    categoryId.value = rule?.categoryId;
    accountId.value = rule?.accountId ?? accounts.first['id'] as int;
    frequency.value = rule?.frequency ?? RecurringFrequency.monthly;
    startDate.value = rule?.startDate ?? DateTime.now();
    amountController.text = CurrencyInputFormatter.initial(rule?.amount ?? 0);
    noteController.text = rule?.note ?? '';
  }

  void setType(String value) {
    type.value = value;
    categoryId.value = null;
  }

  Future<void> pickStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) startDate.value = picked;
  }

  Future<void> save() async {
    final amount = CurrencyInputFormatter.parse(amountController.text);
    if (amount <= 0) {
      AppToast.warning('Peringatan', 'Masukkan nominal yang valid');
      return;
    }
    if (categoryId.value == null) {
      AppToast.warning('Peringatan', 'Pilih kategori terlebih dahulu');
      return;
    }
    if (isWorking.value) return;
    isWorking.value = true;
    try {
      await _persist(amount);
      final created = await RecurringService.to.runDue();
      refreshAllGlobalData();
      await loadRules();
      Get.back();
      AppToast.success(
          'Tersimpan',
          created > 0
              ? '$created transaksi jatuh tempo dicatat'
              : 'Transaksi berulang disimpan');
    } catch (e) {
      AppToast.error('Gagal', 'Transaksi berulang tidak dapat disimpan');
    } finally {
      isWorking.value = false;
    }
  }

  Future<void> _persist(int amount) async {
    final rule = RecurringRule(
      type: type.value,
      amount: amount,
      categoryId: categoryId.value!,
      accountId: accountId.value!,
      note: noteController.text.trim(),
      frequency: frequency.value,
      startDate: startDate.value,
      lastRunDate: _keptLastRun(),
      isActive: _editing?.isActive ?? true,
    );
    final db = DatabaseHelper.instance;
    if (editingId == null) {
      await db.insertRecurringRule(rule.toRow());
    } else {
      await db.updateRecurringRule(editingId!, rule.toRow());
    }
  }

  /// Keeps the generation history unless the schedule moved into the future,
  /// so editing a rule never back-fills duplicates (data-model.md).
  DateTime? _keptLastRun() {
    final old = _editing;
    if (old == null) return null;
    final scheduleChanged = old.frequency != frequency.value ||
        RecurringRule.dateOnly(old.startDate) !=
            RecurringRule.dateOnly(startDate.value);
    if (scheduleChanged && startDate.value.isAfter(DateTime.now())) return null;
    return old.lastRunDate;
  }

  Future<void> toggleActive(RecurringRule rule, bool active) async {
    final row = rule.toRow()..['is_active'] = active ? 1 : 0;
    await DatabaseHelper.instance.updateRecurringRule(rule.id!, row);
    if (active) {
      await RecurringService.to.runDue();
      refreshAllGlobalData();
    }
    await loadRules();
  }

  /// "Hapus" from the edit form.
  Future<void> deleteEditing() async {
    final rule = _editing;
    if (rule == null) return;
    if (await delete(rule)) Get.back();
  }

  Future<bool> delete(RecurringRule rule) async {
    final ok = await AppDialog.confirm(
      title: 'Hapus transaksi berulang?',
      message: 'Transaksi yang sudah tercatat tidak ikut terhapus.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!ok) return false;
    await DatabaseHelper.instance.deleteRecurringRule(rule.id!);
    await loadRules();
    refreshAllGlobalData();
    AppToast.success('Dihapus', 'Transaksi berulang telah dihapus');
    return true;
  }
}
