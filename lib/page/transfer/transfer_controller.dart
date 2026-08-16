import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/utils/data_refresh.dart';

class TransferController extends GetxController {
  final sourceAmountStr = '0'.obs;
  final destAmountStr = '0'.obs;
  final activeField = 'source'.obs;
  final isSynced = true.obs;
  
  final isNumpadVisible = false.obs;

  void toggleNumpad() {
    isNumpadVisible.value = !isNumpadVisible.value;
  }
  
  final sourceAccountId = RxnInt();
  final sourceAccountName = 'CASH'.obs;
  final destinationAccountId = RxnInt();
  final destinationAccountName = 'BCA'.obs;
  final availableAccounts = <Map<String, dynamic>>[].obs;
  
  final selectedDate = DateTime.now().obs;
  
  int get sourceAccountBalance {
    final account = availableAccounts.firstWhereOrNull((a) => a['id'] == sourceAccountId.value);
    return account?['balance'] as int? ?? 0;
  }
  
  int get destinationAccountBalance {
    final account = availableAccounts.firstWhereOrNull((a) => a['id'] == destinationAccountId.value);
    return account?['balance'] as int? ?? 0;
  }
  
  final noteTextController = TextEditingController();
  final note = ''.obs;
  final noteHistory = <String>[].obs;
  final RxBool isWorking = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accs = await DatabaseHelper.instance.readAllAccounts();
    if (accs.isNotEmpty) {
      availableAccounts.value = accs;
      sourceAccountId.value = accs.first['id'] as int;
      sourceAccountName.value = accs.first['name'].toString();
      if (accs.length > 1) {
        destinationAccountId.value = accs[1]['id'] as int;
        destinationAccountName.value = accs[1]['name'].toString();
      } else {
        destinationAccountId.value = accs.first['id'] as int;
        destinationAccountName.value = accs.first['name'].toString();
      }
    }
  }

  @override
  void onClose() {
    noteTextController.dispose();
    super.onClose();
  }

  void setActiveField(String field) {
    activeField.value = field;
    isSynced.value = false;
  }

  Future<void> onNumpadPressed(String key) async {
    if (key == 'delete') {
      _handleDelete();
    } else if (key == 'C') {
      sourceAmountStr.value = '0';
      destAmountStr.value = '0';
      isSynced.value = true;
      activeField.value = 'source';
    } else if (key == 'confirm') {
      _handleConfirm();
    } else if (key == '+' || key == '-') {
      // Operator placeholder
    } else {
      _handleDigit(key);
    }
  }

  void _handleDelete() {
    if (activeField.value == 'source') {
      if (sourceAmountStr.value.length > 1) {
        sourceAmountStr.value = sourceAmountStr.value.substring(0, sourceAmountStr.value.length - 1);
      } else {
        sourceAmountStr.value = '0';
      }
      if (isSynced.value) destAmountStr.value = sourceAmountStr.value;
    } else {
      if (destAmountStr.value.length > 1) {
        destAmountStr.value = destAmountStr.value.substring(0, destAmountStr.value.length - 1);
      } else {
        destAmountStr.value = '0';
      }
    }
  }

  void _handleDigit(String key) {
    if (activeField.value == 'source') {
      if (sourceAmountStr.value.length >= 12) {
        if (!Get.isSnackbarOpen) {
          Get.snackbar('Batas Maksimal', 'Maksimal 12 digit angka', snackPosition: SnackPosition.BOTTOM);
        }
        return;
      }
      if (sourceAmountStr.value == '0') {
        sourceAmountStr.value = key;
      } else {
        sourceAmountStr.value += key;
      }
      if (isSynced.value) destAmountStr.value = sourceAmountStr.value;
    } else {
      if (destAmountStr.value.length >= 12) {
        if (!Get.isSnackbarOpen) {
          Get.snackbar('Batas Maksimal', 'Maksimal 12 digit angka', snackPosition: SnackPosition.BOTTOM);
        }
        return;
      }
      if (destAmountStr.value == '0') {
        destAmountStr.value = key;
      } else {
        destAmountStr.value += key;
      }
    }
  }

  Future<void> _handleConfirm() async {
    if (isWorking.value) return;
    
    final sAmount = int.tryParse(sourceAmountStr.value) ?? 0;
    final dAmount = int.tryParse(destAmountStr.value) ?? 0;
    
    if (sourceAccountId.value == destinationAccountId.value) {
      if (!Get.isSnackbarOpen) {
        Get.snackbar('Peringatan', 'Rekening asal dan tujuan tidak boleh sama',
            backgroundColor: Colors.orange.shade800, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      }
      return;
    }

    if (sAmount <= 0 || dAmount <= 0) {
      if (!Get.isSnackbarOpen) {
        Get.snackbar('Peringatan', 'Nominal tidak boleh 0',
            backgroundColor: Colors.orange.shade800, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      }
      return;
    }

    if (sAmount < dAmount) {
      if (!Get.isSnackbarOpen) {
        Get.snackbar('Peringatan', 'Nominal dipotong tidak boleh lebih kecil dari yang diterima',
            backgroundColor: Colors.orange.shade800, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      }
      return;
    }

    if (note.value.isNotEmpty && !noteHistory.contains(note.value)) {
      noteHistory.insert(0, note.value);
    }
    
    final adminFee = sAmount - dAmount;

    final transaction = {
      'type': 'transfer',
      'amount': dAmount, // Baseline is what destination gets
      'category_id': null,
      'note': note.value,
      'account_id': sourceAccountId.value,
      'destination_account_id': destinationAccountId.value,
      'date': selectedDate.value.toIso8601String(),
      'admin_fee': adminFee,
      'admin_fee_type': 'Pengirim', // D deducted + (S-D) = S total deducted. Works perfectly!
    };
    
    isWorking.value = true;
    try {
      await DatabaseHelper.instance.insertTransferWithBalanceUpdate(
          transaction, sourceAccountId.value!, destinationAccountId.value!, dAmount, adminFee, 'Pengirim');
      refreshAllGlobalData();

      Get.back();
      Get.snackbar(
        'Berhasil', 
        'Transfer berhasil disimpan',
        backgroundColor: Colors.green.shade800,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar('Error', 'Gagal menyimpan transfer',
          backgroundColor: Colors.red.shade800, colorText: Colors.white);
    } finally {
      isWorking.value = false;
    }
  }

  void onSuggestionTapped(String suggestion) {
    noteTextController.text = suggestion;
    note.value = suggestion;
  }

  Future<void> pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate.value) {
      selectedDate.value = picked;
    }
  }
}
