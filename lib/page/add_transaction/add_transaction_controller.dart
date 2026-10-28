import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/database/transaction_store.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/services/sound_service.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/data_refresh.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/page/account_management/account_management_controller.dart';
import 'package:artavia/widgets/components/app_feedback.dart';

class AddTransactionController extends GetxController {
  static const _maxDigits = 12;

  final currentTab = 'Pengeluaran'.obs;
  final amountStr = '0'.obs;
  // For calculator: pending operand and operator
  final _pendingValueObs = 0.obs;
  final _pendingOperatorObs = ''.obs;

  final isNumpadVisible = false.obs;
  final isLoading = true.obs;

  void toggleNumpad() {
    isNumpadVisible.value = !isNumpadVisible.value;
  }

  // Public getters for screen binding
  RxInt get pendingValue => _pendingValueObs;
  RxString get pendingOperator => _pendingOperatorObs;

  final note = ''.obs;
  final selectedDate = DateTime.now().obs;
  final selectedAccountId = RxnInt();
  final selectedAccountName = ''.obs;
  final availableAccounts = <Map<String, dynamic>>[].obs;
  final availableCategories = <Map<String, dynamic>>[].obs;

  int get selectedAccountBalance {
    final account = availableAccounts
        .firstWhereOrNull((a) => a['id'] == selectedAccountId.value);
    return account?['balance'] as int? ?? 0;
  }

  final noteHistory = <String>[].obs;
  final RxBool isWorking = false.obs;
  final TextEditingController noteTextController = TextEditingController();

  // Selected category
  final selectedCategoryId = RxnInt();
  final selectedCategoryName = ''.obs;

  // Quick amount shortcuts
  final quickAmounts = [5000, 10000, 20000, 50000, 100000, 500000];

  int? editId;

  bool get isEdit => editId != null;

  /// Read once from the route, before the async init finishes.
  final bool isEditArgs = Get.arguments?['isEdit'] == true;

  void onTabChanged(String tab) {
    if (tab == 'Transfer') {
      Get.offNamed(transferRoute, preventDuplicates: false);
      return;
    }
    currentTab.value = tab;
    selectedCategoryId.value = null;
    selectedCategoryName.value = '';
    _pendingValueObs.value = 0;
    _pendingOperatorObs.value = '';
    amountStr.value = '0';
    _loadCategories();
  }

  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  Future<void> _initData() async {
    final args = Get.arguments;
    if (args != null &&
        args['initialTab'] != null &&
        args['initialTab'] != 'Transfer') {
      currentTab.value = args['initialTab'] as String;
    } else if (isEditArgs) {
      editId = int.tryParse(args['id'].toString());
      currentTab.value =
          args['type'] == 'pemasukan' ? 'Pemasukan' : 'Pengeluaran';
      amountStr.value = '${args['amount'] ?? 0}';
      note.value = args['note'] ?? '';
      noteTextController.text = note.value;
      if (args['date'] != null) selectedDate.value = args['date'] as DateTime;
    }

    await _loadAccounts();
    await _loadCategories();

    if (isEditArgs) {
      _selectAccount(args['account_id'] as int?);
      final catName = args['category'] as String?;
      final cat =
          availableCategories.firstWhereOrNull((c) => c['name'] == catName);
      if (cat != null) {
        selectedCategoryId.value = cat['id'] as int;
        selectedCategoryName.value = catName!;
        isNumpadVisible.value = true;
      }
    }
    isLoading.value = false;
  }

  /// Reloads categories (e.g. after adding one) without clearing the amount.
  Future<void> reloadCategories() async {
    final keep = selectedCategoryId.value;
    final keepName = selectedCategoryName.value;
    await _loadCategories();
    if (availableCategories.any((c) => c['id'] == keep)) {
      selectedCategoryId.value = keep;
      selectedCategoryName.value = keepName;
    }
  }

  Future<void> _loadCategories() async {
    final type =
        currentTab.value == 'Pengeluaran' ? 'pengeluaran' : 'pemasukan';
    final cats = await DatabaseHelper.instance.readAllCategories();
    availableCategories.value = cats
        .where((c) => c['type'] == type)
        .map((c) => {
              'id': c['id'],
              'name': c['name'],
              'icon_code': c['icon_code'],
              'icon_path': c['icon_path'],
              'color_val': c['color_val'],
            })
        .toList();
    selectedCategoryId.value = null;
    selectedCategoryName.value = '';
  }

  Future<void> _loadAccounts() async {
    final accs = await DatabaseHelper.instance.readAllAccounts();
    availableAccounts.value = accs;
    if (accs.isNotEmpty) _selectAccount(accs.first['id'] as int);
  }

  /// Keeps the current selection when [id] no longer exists (deleted account).
  void _selectAccount(int? id) {
    final acc = availableAccounts.firstWhereOrNull((a) => a['id'] == id);
    if (acc == null) return;
    selectedAccountId.value = acc['id'] as int;
    selectedAccountName.value = acc['name'] as String;
  }

  void selectAccount(Map<String, dynamic> acc) =>
      _selectAccount(acc['id'] as int);

  /// Opens the add-account form and reloads accounts when it closes (FR-012).
  Future<void> createAccount() async {
    await AccountManagementController.openEditor();
    await _loadAccounts();
  }

  // ─── Numpad logic with calculator support ───────────────────────────────
  Future<void> onNumpadPressed(String key) async {
    switch (key) {
      case 'delete':
        final s = amountStr.value;
        amountStr.value = s.length > 1 ? s.substring(0, s.length - 1) : '0';
      case 'C':
        amountStr.value = '0';
        _pendingValueObs.value = 0;
        _pendingOperatorObs.value = '';
      case '+' || '-':
        _pendingValueObs.value = int.tryParse(amountStr.value) ?? 0;
        _pendingOperatorObs.value = key;
        amountStr.value = '0';
      case '=':
        _resolvePendingOperation();
      case 'confirm':
        _resolvePendingOperation();
        await _save();
      default:
        _appendDigit(key);
    }
  }

  /// Applies a pending +/- to the display. Returns true if one was applied.
  bool _resolvePendingOperation() {
    if (_pendingOperatorObs.value.isEmpty) return false;
    final a = _pendingValueObs.value;
    final b = int.tryParse(amountStr.value) ?? 0;
    final result = _pendingOperatorObs.value == '+' ? a + b : (a - b).abs();
    amountStr.value = '$result';
    _pendingValueObs.value = 0;
    _pendingOperatorObs.value = '';
    return true;
  }

  void _appendDigit(String key) {
    final next = amountStr.value == '0' ? key : amountStr.value + key;
    final normalized = (int.tryParse(next) ?? 0).toString();
    if (normalized.length > _maxDigits) {
      AppToast.warning('Batas Maksimal', 'Maksimal $_maxDigits digit angka');
      return;
    }
    amountStr.value = normalized;
  }

  String? _validationError(int amount) {
    if (selectedAccountId.value == null) return 'Buat rekening terlebih dahulu';
    if (amount <= 0) return 'Masukkan nominal yang valid';
    if (selectedCategoryId.value == null) {
      return 'Pilih kategori terlebih dahulu';
    }
    return null;
  }

  Future<void> _save() async {
    if (isWorking.value) return;
    final amount = int.tryParse(amountStr.value) ?? 0;
    final error = _validationError(amount);
    if (error != null) {
      AppToast.warning('Peringatan', error);
      return;
    }
    if (note.value.isNotEmpty && !noteHistory.contains(note.value)) {
      noteHistory.insert(0, note.value);
      if (noteHistory.length > 10) noteHistory.removeLast();
    }

    final type = currentTab.value.toLowerCase();
    final row = {
      'type': type,
      'amount': amount,
      'category_id': selectedCategoryId.value,
      'note': note.value,
      'account_id': selectedAccountId.value,
      'date': selectedDate.value.toIso8601String(),
    };

    isWorking.value = true;
    try {
      final db = DatabaseHelper.instance;
      if (isEdit) {
        await db.replaceTransaction(editId!, row);
      } else {
        await db.addTransaction(row);
      }
      refreshAllGlobalData();
      SoundService.to.playSuccess();
      final overBudget =
          type == 'pengeluaran' ? await _overBudgetMessage() : null;

      if (isEdit) {
        Get.until((route) => route.isFirst);
      } else {
        Get.back();
      }

      if (overBudget != null) {
        AppToast.warning('Melewati anggaran', overBudget);
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

  /// Warning text when the saved expense pushed its category over budget (FR-033).
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
    return '${selectedCategoryName.value}: ${money.format(used)} dari ${money.format(limit)}';
  }

  // Quick amount add shortcut
  void addQuickAmount(int amount) {
    final newAmount = (int.tryParse(amountStr.value) ?? 0) + amount;
    if (newAmount.toString().length > _maxDigits) {
      AppToast.warning('Batas Maksimal', 'Nominal terlalu besar');
      return;
    }
    amountStr.value = newAmount.toString();
  }

  void selectCategory(int id, String name) {
    selectedCategoryId.value = id;
    selectedCategoryName.value = name;
    isNumpadVisible.value = true;
  }

  void onSuggestionTapped(String suggestion) {
    note.value = suggestion;
    noteTextController.text = suggestion;
  }

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

  @override
  void onClose() {
    noteTextController.dispose();
    super.onClose();
  }
}
