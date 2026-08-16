import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/utils/data_refresh.dart';

class AddTransactionController extends GetxController {
  final currentTab = 'Pengeluaran'.obs;
  final amountStr = '0'.obs;
  // For calculator: pending operand and operator
  final _pendingValueObs = 0.obs;
  final _pendingOperatorObs = ''.obs;
  
  final isNumpadVisible = false.obs;

  void toggleNumpad() {
    isNumpadVisible.value = !isNumpadVisible.value;
  }

  // Public getters for screen binding
  RxInt get pendingValue => _pendingValueObs;
  RxString get pendingOperator => _pendingOperatorObs;

  final note = ''.obs;
  final selectedDate = DateTime.now().obs;
  final selectedAccountId = RxnInt();
  final selectedAccountName = 'CASH'.obs;
  final availableAccounts = <Map<String, dynamic>>[].obs;
  final availableCategories = <Map<String, dynamic>>[].obs;

  int get selectedAccountBalance {
    final account = availableAccounts.firstWhereOrNull((a) => a['id'] == selectedAccountId.value);
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

  void onTabChanged(String tab) {
    currentTab.value = tab;
    selectedCategoryId.value = null;
    selectedCategoryName.value = '';
    _pendingValueObs.value = 0;
    _pendingOperatorObs.value = '';
    amountStr.value = '0';
    if (tab == 'Transfer') {
      Get.back();
      Get.toNamed('/transfer');
      return;
    }
    _loadCategories();
  }

  int? editId;
  int? oldAmount;
  String? oldType;
  int? oldAccountId;

  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  Future<void> _initData() async {
    final args = Get.arguments;
    if (args != null) {
      if (args['initialTab'] != null) {
        final tab = args['initialTab'] as String;
        if (tab != 'Transfer') {
          currentTab.value = tab;
        }
      } else if (args['isEdit'] == true) {
        editId = int.tryParse(args['id'].toString());
        oldAmount = args['amount'] as int?;
        oldType = args['type'] as String?;
        oldAccountId = args['account_id'] as int?;
        
        final type = oldType ?? 'pengeluaran';
        currentTab.value = type == 'pengeluaran' ? 'Pengeluaran' : 'Pemasukan';
        amountStr.value = (oldAmount ?? 0).toString();
        note.value = args['note'] ?? '';
        noteTextController.text = note.value;
        if (args['date'] != null) selectedDate.value = args['date'] as DateTime;
      }
    }
    
    await _loadAccounts();
    await _loadCategories();

    if (args != null && args['isEdit'] == true) {
      if (oldAccountId != null) {
        for (var a in availableAccounts) {
          if (a['id'] == oldAccountId) {
            selectedAccountId.value = oldAccountId;
            selectedAccountName.value = a['name'] as String;
            break;
          }
        }
      }
      final catName = args['category'] as String?;
      if (catName != null) {
        for (var c in availableCategories) {
          if (c['name'] == catName) {
            selectedCategoryId.value = c['id'] as int;
            selectedCategoryName.value = catName;
            break;
          }
        }
      }
    }
  }

  Future<void> _loadCategories() async {
    final cats = await DatabaseHelper.instance.readAllCategories();
    final List<Map<String, dynamic>> parsedCats = [];
    for (var c in cats) {
      final type =
          currentTab.value == 'Pengeluaran' ? 'pengeluaran' : 'pemasukan';
      if (c['type'] == type) {
        final iconCode = c['icon_code'] as int?;
        final iconPath = c['icon_path'] as String?;
        
        Color colorData = Colors.grey;
        if (c['color_val'] != null) {
          colorData = Color(c['color_val'] as int);
        }
        parsedCats.add({
          'id': c['id'],
          'name': c['name'],
          'icon_code': iconCode,
          'icon_path': iconPath,
          'color': colorData,
        });
      }
    }
    availableCategories.value = parsedCats;
    selectedCategoryId.value = null;
    selectedCategoryName.value = '';
  }

  Future<void> _loadAccounts() async {
    final accs = await DatabaseHelper.instance.readAllAccounts();
    if (accs.isNotEmpty) {
      availableAccounts.value = accs;
      selectedAccountId.value = accs.first['id'] as int;
      selectedAccountName.value = accs.first['name'].toString();
    }
  }

  // ─── Numpad logic with calculator support ───────────────────────────────
  Future<void> onNumpadPressed(String key) async {
    if (key == 'delete') {
      if (amountStr.value.length > 1) {
        amountStr.value =
            amountStr.value.substring(0, amountStr.value.length - 1);
      } else {
        amountStr.value = '0';
      }
    } else if (key == 'C') {
      amountStr.value = '0';
      _pendingValueObs.value = 0;
      _pendingOperatorObs.value = '';
    } else if (key == '+' || key == '-') {
      // Store current value and operator, reset display for next operand
      _pendingValueObs.value = int.tryParse(amountStr.value) ?? 0;
      _pendingOperatorObs.value = key;
      amountStr.value = '0';
    } else if (key == '=' || key == 'confirm') {
      if (key == 'confirm' && isWorking.value) return;

      // If there's a pending operation, resolve it first
      if (_pendingOperatorObs.value.isNotEmpty) {
        final a = _pendingValueObs.value;
        final b = int.tryParse(amountStr.value) ?? 0;
        final result = _pendingOperatorObs.value == '+' ? a + b : (a - b).abs();
        amountStr.value = result.toString();
        _pendingValueObs.value = 0;
        _pendingOperatorObs.value = '';
        // If triggered by '=' key, just show result; if 'confirm', save
        if (key == '=') return;
      }

      final parsedAmount = int.tryParse(amountStr.value) ?? 0;

      if (parsedAmount <= 0) {
        if (!Get.isSnackbarOpen) {
          Get.snackbar('Peringatan', 'Masukkan nominal yang valid',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange.shade800,
              colorText: Colors.white,
              margin: const EdgeInsets.all(16));
        }
        return;
      }

      if (selectedCategoryId.value == null) {
        if (!Get.isSnackbarOpen) {
          Get.snackbar('Peringatan', 'Pilih kategori terlebih dahulu',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange.shade800,
              colorText: Colors.white,
              margin: const EdgeInsets.all(16));
        }
        return;
      }

      if (note.value.isNotEmpty && !noteHistory.contains(note.value)) {
        noteHistory.insert(0, note.value);
        if (noteHistory.length > 10) noteHistory.removeLast();
      }

      final type = currentTab.value.toLowerCase();
      final transaction = {
        'type': type,
        'amount': parsedAmount,
        'category_id': selectedCategoryId.value,
        'note': note.value,
        'account_id': selectedAccountId.value,
        'date': selectedDate.value.toIso8601String(),
      };

      isWorking.value = true;
      try {
        if (editId != null && oldAccountId != null && oldAmount != null && oldType != null) {
          final oldIsExpense = oldType == 'pengeluaran';
          final oldIsTransfer = oldType == 'transfer';
          await DatabaseHelper.instance.deleteTransactionWithBalanceUpdate(
              editId!, oldAccountId, null, oldAmount!, oldIsExpense, oldIsTransfer);
        }

        final multiplier = type == 'pengeluaran' ? -1 : 1;
        await DatabaseHelper.instance.insertTransactionWithBalanceUpdate(
            transaction, selectedAccountId.value!, parsedAmount * multiplier);
        refreshAllGlobalData();

        if (editId != null) {
          Get.until((route) => route.isFirst);
        } else {
          Get.back();
        }

        Get.snackbar(
          editId != null ? 'Diperbarui!' : 'Tersimpan!',
          '${type == 'pengeluaran' ? 'Pengeluaran' : 'Pemasukan'} berhasil ${editId != null ? 'diperbarui' : 'dicatat'}',
          backgroundColor: Colors.green.shade800,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.check_circle, color: Colors.white),
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        Get.snackbar('Error', 'Gagal menyimpan transaksi',
            backgroundColor: Colors.red.shade800, colorText: Colors.white);
      } finally {
        isWorking.value = false;
      }
    } else {
      // Digit
      if (amountStr.value.length >= 12) {
        if (!Get.isSnackbarOpen) {
          Get.snackbar('Batas Maksimal', 'Maksimal 12 digit angka', snackPosition: SnackPosition.BOTTOM);
        }
        return;
      }
      if (amountStr.value == '0') {
        amountStr.value = key;
      } else {
        amountStr.value += key;
      }
    }
  }

  // Quick amount add shortcut
  void addQuickAmount(int amount) {
    final current = int.tryParse(amountStr.value) ?? 0;
    final newAmount = current + amount;
    if (newAmount.toString().length > 12) {
      if (!Get.isSnackbarOpen) {
        Get.snackbar('Batas Maksimal', 'Nominal terlalu besar', snackPosition: SnackPosition.BOTTOM);
      }
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
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFCA28),
            onPrimary: Colors.black,
            surface: Color(0xFF1E1E1E),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      selectedDate.value = picked;
    }
  }

  @override
  void onClose() {
    noteTextController.dispose();
    super.onClose();
  }
}
