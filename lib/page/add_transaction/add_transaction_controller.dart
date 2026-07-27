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

  // Public getters for screen binding
  RxInt get pendingValue => _pendingValueObs;
  RxString get pendingOperator => _pendingOperatorObs;

  final note = ''.obs;
  final selectedDate = DateTime.now().obs;
  final selectedAccountId = RxnInt();
  final selectedAccountName = 'CASH'.obs;
  final availableAccounts = <Map<String, dynamic>>[].obs;
  final availableCategories = <Map<String, dynamic>>[].obs;

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

  @override
  void onInit() {
    super.onInit();
    // Support initialTab argument from home speed-dial
    final args = Get.arguments;
    if (args != null && args['initialTab'] != null) {
      final tab = args['initialTab'] as String;
      if (tab != 'Transfer') {
        currentTab.value = tab;
      }
    }
    _loadAccounts();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await DatabaseHelper.instance.readAllCategories();
    final List<Map<String, dynamic>> parsedCats = [];
    for (var c in cats) {
      final type =
          currentTab.value == 'Pengeluaran' ? 'pengeluaran' : 'pemasukan';
      if (c['type'] == type) {
        IconData iconData = Icons.category;
        if (c['icon_code'] != null) {
          iconData =
              // ignore: non_const_argument_for_const_parameter
              IconData(c['icon_code'] as int, fontFamily: 'MaterialIcons');
        }
        Color colorData = Colors.grey;
        if (c['color_val'] != null) {
          colorData = Color(c['color_val'] as int);
        }
        parsedCats.add({
          'id': c['id'],
          'name': c['name'],
          'icon': iconData,
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
        Get.snackbar('Peringatan', 'Masukkan nominal yang valid',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade800,
            colorText: Colors.white,
            margin: const EdgeInsets.all(16));
        return;
      }

      if (selectedCategoryId.value == null) {
        Get.snackbar('Peringatan', 'Pilih kategori terlebih dahulu',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade800,
            colorText: Colors.white,
            margin: const EdgeInsets.all(16));
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
        final multiplier = type == 'pengeluaran' ? -1 : 1;
        await DatabaseHelper.instance.insertTransactionWithBalanceUpdate(
            transaction, selectedAccountId.value!, parsedAmount * multiplier);
        refreshAllGlobalData();

        Get.back();
        Get.snackbar(
          'Tersimpan!',
          '${type == 'pengeluaran' ? 'Pengeluaran' : 'Pemasukan'} berhasil dicatat',
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
        Get.snackbar('Batas Maksimal', 'Maksimal 12 digit angka', snackPosition: SnackPosition.BOTTOM);
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
      Get.snackbar('Batas Maksimal', 'Nominal terlalu besar', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    amountStr.value = newAmount.toString();
  }

  void selectCategory(int id, String name) {
    selectedCategoryId.value = id;
    selectedCategoryName.value = name;
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
