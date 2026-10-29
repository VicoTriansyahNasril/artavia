import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/database/transaction_store.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/services/haptics_service.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/core/utils/calc_engine.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/data_refresh.dart';
import 'package:artavia/core/utils/finance_calc.dart';
import 'package:artavia/page/account_management/account_management_controller.dart';
import 'package:artavia/page/transfer/transfer_controller.dart';
import 'package:artavia/widgets/components/app_feedback.dart';

/// Catat screen (US2): one keypad-driven form for Pengeluaran, Pemasukan and
/// Transfer. The typed amount survives segment switches (FR-006); the
/// Transfer segment's own state lives in [TransferController].
class AddTransactionController extends GetxController {
  AddTransactionController({this.initialTab});

  static const tabs = ['Pengeluaran', 'Pemasukan', 'Transfer'];
  static const gridSize = 10;

  /// Set by the route (`/transfer` opens Catat on the Transfer segment).
  final String? initialTab;

  final currentTab = 'Pengeluaran'.obs;
  bool get isTransfer => currentTab.value == 'Transfer';
  String get _dbType =>
      currentTab.value == 'Pemasukan' ? 'pemasukan' : 'pengeluaran';

  // ─── Amount (shared with the transfer segment) ──────────────────────────
  final calc = CalcEngine();
  final amount = 0.obs;
  final expression = ''.obs;

  final isLoading = true.obs;
  final isWorking = false.obs;

  final note = ''.obs;
  final selectedDate = DateTime.now().obs;
  final selectedAccountId = RxnInt();
  final availableAccounts = <Map<String, dynamic>>[].obs;

  /// Every non-archived category of the current type, ranked by use.
  final rankedCategories = <Map<String, dynamic>>[].obs;
  List<Map<String, dynamic>> get gridCategories =>
      rankedCategories.take(gridSize).toList();

  final selectedCategoryId = RxnInt();

  int? editId;
  bool get isEdit => editId != null;

  late final TransferController transfer;

  Map<String, dynamic>? get selectedAccount => availableAccounts
      .firstWhereOrNull((a) => a['id'] == selectedAccountId.value);

  Map<String, dynamic>? get selectedCategory => rankedCategories
      .firstWhereOrNull((c) => c['id'] == selectedCategoryId.value);

  /// FR-008: "Simpan" is enabled only for a positive result.
  bool get canSave => isTransfer ? transfer.canSave : amount.value > 0;

  /// Error under the big amount when an expression ends ≤ 0.
  String? get amountError =>
      !calc.isEmpty && amount.value <= 0 && calc.hasOperator
          ? 'Jumlah harus lebih dari 0'
          : null;

  @override
  void onInit() {
    super.onInit();
    transfer = Get.put(TransferController(amount));
    _init();
  }

  Future<void> _init() async {
    final args = Get.arguments is Map ? Get.arguments as Map : const {};
    final editing = args['isEdit'] == true;
    final argTab = args['initialTab'] as String?;

    if (editing) {
      editId = int.tryParse('${args['id']}');
      currentTab.value = switch (args['type']) {
        'pemasukan' => 'Pemasukan',
        'transfer' => 'Transfer',
        _ => 'Pengeluaran',
      };
      note.value = args['note'] as String? ?? '';
      if (args['date'] is DateTime) selectedDate.value = args['date'];
    } else {
      currentTab.value = argTab ?? initialTab ?? 'Pengeluaran';
    }

    await _loadAccounts();
    await _loadCategories();

    if (editing && args['type'] != 'transfer') {
      setAmount(args['amount'] as int? ?? 0);
      _selectAccount(args['account_id'] as int?);
      final catId = args['category_id'] as int?;
      selectedCategoryId.value = catId ??
          rankedCategories.firstWhereOrNull(
              (c) => c['name'] == args['category'])?['id'] as int?;
    }
    transfer.attach(
      availableAccounts,
      editArgs: editing && args['type'] == 'transfer' ? args : null,
      preferredSourceId: selectedAccountId.value,
    );
    if (editing && args['type'] == 'transfer') {
      setAmount(transfer.editAmount);
    }
    isLoading.value = false;
  }

  void setAmount(int value) {
    calc.setValue(value);
    _syncAmount();
  }

  void _syncAmount() {
    amount.value = calc.result;
    expression.value =
        calc.expression(groupSeparator: CurrencyService.to.groupSeparator);
  }

  // ─── Segment ─────────────────────────────────────────────────────────────

  void onTabChanged(String tab) {
    if (tab == currentTab.value) return;
    currentTab.value = tab;
    if (tab != 'Transfer') _loadCategories();
  }

  // ─── Keypad ──────────────────────────────────────────────────────────────

  void onKey(String key) {
    if (isTransfer && transfer.editingFee) {
      transfer.pressFeeKey(key);
      return;
    }
    if (!calc.press(key)) {
      AppToast.warning(
          'Batas maksimal', 'Maksimal ${CalcEngine.maxDigits} digit angka');
      return;
    }
    _syncAmount();
  }

  // ─── Data ────────────────────────────────────────────────────────────────

  Future<void> _loadAccounts() async {
    final accs = await DatabaseHelper.instance.readAllAccounts();
    availableAccounts.value =
        accs.where((a) => (a['is_archived'] ?? 0) != 1).toList();
    if (availableAccounts.isEmpty) return;
    // FR-010: default to the last used account.
    final last = SettingsService.to.lastAccountId;
    _selectAccount(availableAccounts.any((a) => a['id'] == last)
        ? last
        : availableAccounts.first['id'] as int);
  }

  Future<void> _loadCategories() async {
    final db = DatabaseHelper.instance;
    final cats = await db.readAllCategories();
    final usage = await db.categoryUsage(_dbType);
    final keep = selectedCategoryId.value;
    rankedCategories.value =
        rankCategories(cats.where((c) => c['type'] == _dbType), usage);
    selectedCategoryId.value =
        rankedCategories.any((c) => c['id'] == keep) ? keep : null;
  }

  /// Reloads categories (e.g. after adding one) and keeps the selection.
  Future<void> reloadCategories() => _loadCategories();

  void _selectAccount(int? id) {
    if (availableAccounts.any((a) => a['id'] == id)) {
      selectedAccountId.value = id;
    }
  }

  void selectAccount(int id) => _selectAccount(id);

  void selectCategory(int id) => selectedCategoryId.value = id;

  /// Opens the add-account form and reloads accounts when it closes.
  Future<void> createAccount() async {
    await AccountManagementController.openEditor();
    await _loadAccounts();
    transfer.attach(availableAccounts,
        preferredSourceId: transfer.sourceId.value ?? selectedAccountId.value);
  }

  void setNote(String value) => note.value = value.trim();

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    // Keep the current time of day so ordering within a day stays natural.
    final now = DateTime.now();
    selectedDate.value =
        DateTime(picked.year, picked.month, picked.day, now.hour, now.minute);
  }

  // ─── Save ────────────────────────────────────────────────────────────────

  Future<void> save() async {
    if (isWorking.value || !canSave) return;
    if (isTransfer) {
      await _finish(() => transfer.save(
          note: note.value, date: selectedDate.value, replaceId: editId));
      return;
    }
    if (selectedAccountId.value == null) {
      AppToast.warning('Belum ada rekening', 'Buat rekening terlebih dahulu');
      return;
    }
    if (selectedCategoryId.value == null) {
      AppToast.warning('Pilih kategori', 'Ketuk salah satu kategori');
      return;
    }
    final row = {
      'type': _dbType,
      'amount': amount.value,
      'category_id': selectedCategoryId.value,
      'note': note.value,
      'account_id': selectedAccountId.value,
      'date': selectedDate.value.toIso8601String(),
    };
    await _finish(() async {
      final db = DatabaseHelper.instance;
      if (isEdit) {
        await db.replaceTransaction(editId!, row);
      } else {
        await db.addTransaction(row);
      }
      return _dbType == 'pengeluaran' ? _overBudgetMessage() : null;
    });
  }

  /// Runs [write], then refreshes, remembers the account, closes and toasts.
  /// [write] may return a warning to show instead of the success toast.
  Future<void> _finish(Future<String?> Function() write) async {
    isWorking.value = true;
    try {
      final warning = await write();
      final account =
          isTransfer ? transfer.sourceId.value : selectedAccountId.value;
      if (account != null) {
        await SettingsService.to
            .set(SettingsService.keyLastAccountId, '$account');
      }
      refreshAllGlobalData();
      if (Get.isRegistered<HapticsService>()) HapticsService.to.success();
      if (isEdit) {
        Get.until((route) => route.isFirst);
      } else {
        Get.back();
      }
      if (warning != null) {
        AppToast.warning('Melewati anggaran', warning);
      } else {
        AppToast.success(isEdit ? 'Diperbarui' : 'Tersimpan',
            '${currentTab.value} berhasil ${isEdit ? 'diperbarui' : 'dicatat'}');
      }
    } catch (e) {
      AppToast.error('Gagal', 'Transaksi tidak dapat disimpan');
    } finally {
      isWorking.value = false;
    }
  }

  /// Warning when the saved expense pushed its category over budget.
  Future<String?> _overBudgetMessage() async {
    final period =
        Period.containing(selectedDate.value, PeriodService.to.startDay);
    final db = DatabaseHelper.instance;
    final budgets = await db.readBudgetsByMonth(period.year, period.month);
    final budget = budgets
        .firstWhereOrNull((b) => b['category_id'] == selectedCategoryId.value);
    if (budget == null) return null;
    final rows = await db.readTransactionsByRange(period.start, period.end);
    final used = rows
        .where((t) =>
            t['type'] == 'pengeluaran' &&
            t['category_id'] == selectedCategoryId.value)
        .fold<int>(0, (s, t) => s + (t['amount'] as int));
    final limit = budget['budget_amount'] as int;
    if (used <= limit) return null;
    final money = CurrencyService.to;
    return '${selectedCategory?['name'] ?? 'Kategori'}: '
        '${money.money(used, maskable: false)} dari '
        '${money.money(limit, maskable: false)}';
  }

  @override
  void onClose() {
    Get.delete<TransferController>();
    super.onClose();
  }
}
