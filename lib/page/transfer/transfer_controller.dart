import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/utils/data_refresh.dart';

class TransferController extends GetxController {
  final amountStr = '0'.obs;
  
  final sourceAccountId = RxnInt();
  final sourceAccountName = 'CASH'.obs;
  final destinationAccountId = RxnInt();
  final destinationAccountName = 'BCA'.obs;
  final availableAccounts = <Map<String, dynamic>>[].obs;
  
  final selectedDate = DateTime.now().obs;
  
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

  Future<void> onNumpadPressed(String key) async {
    if (key == 'delete') {
      if (amountStr.value.length > 1) {
        amountStr.value = amountStr.value.substring(0, amountStr.value.length - 1);
      } else {
        amountStr.value = '0';
      }
    } else if (key == 'C') {
      amountStr.value = '0';
    } else if (key == 'confirm') {
      if (isWorking.value) return;
      if (note.value.isNotEmpty && !noteHistory.contains(note.value)) {
        noteHistory.insert(0, note.value);
      }
      
      final parsedAmount = int.tryParse(amountStr.value) ?? 0;
      if (parsedAmount > 0) {
        final transaction = {
          'type': 'transfer',
          'amount': parsedAmount,
          'category_id': null, // category not needed for transfer usually, but depends on logic
          'note': note.value,
          'account_id': sourceAccountId.value,
          'destination_account_id': destinationAccountId.value,
          'date': selectedDate.value.toIso8601String(),
        };
        
        isWorking.value = true;
        try {
          await DatabaseHelper.instance.insertTransferWithBalanceUpdate(
              transaction, sourceAccountId.value!, destinationAccountId.value!, parsedAmount);
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
    } else if (key == '+' || key == '-') {
      // Operator placeholder
    } else {
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
