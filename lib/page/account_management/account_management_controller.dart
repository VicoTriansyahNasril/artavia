import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';

// Account type definition
class AccountType {
  final String label;
  final IconData icon;
  final int defaultColorVal;

  const AccountType({
    required this.label,
    required this.icon,
    required this.defaultColorVal,
  });
}

class AccountManagementController extends GetxController {
  final accountGroups = <Map<String, dynamic>>[].obs;

  // Account types with icons and default colors
  static const List<AccountType> accountTypes = [
    AccountType(label: 'Kas Tunai',      icon: Icons.payments_outlined,          defaultColorVal: 0xFFFFCA28),
    AccountType(label: 'Bank',           icon: Icons.account_balance_outlined,    defaultColorVal: 0xFF2196F3),
    AccountType(label: 'Kartu Kredit',   icon: Icons.credit_card_outlined,        defaultColorVal: 0xFFF44336),
    AccountType(label: 'Dompet Digital', icon: Icons.phone_android_outlined,      defaultColorVal: 0xFF4CAF50),
    AccountType(label: 'Tabungan',       icon: Icons.savings_outlined,            defaultColorVal: 0xFF00BCD4),
    AccountType(label: 'Investasi',      icon: Icons.trending_up_rounded,         defaultColorVal: 0xFF9C27B0),
    AccountType(label: 'Pinjaman',       icon: Icons.account_balance_wallet_outlined, defaultColorVal: 0xFFFF9800),
    AccountType(label: 'Kas Bisnis',     icon: Icons.business_center_outlined,    defaultColorVal: 0xFF607D8B),
    AccountType(label: 'Lainnya',        icon: Icons.more_horiz,                  defaultColorVal: 0xFF9E9E9E),
  ];

  // Form State
  final typeValue = 'Kas Tunai'.obs;
  final accountName = ''.obs;
  final balance = 0.obs;
  final excludeFromTotal = false.obs;
  final selectedIconCode = Icons.payments_outlined.codePoint.obs;
  final selectedColorVal = 0xFFFFCA28.obs;

  // Edit mode
  final editingId = Rx<int?>(null);
  bool get isEditMode => editingId.value != null;

  final presetColors = <Color>[
    const Color(0xFFFFCA28),
    const Color(0xFF4CAF50),
    const Color(0xFF2196F3),
    const Color(0xFFF44336),
    const Color(0xFF9C27B0),
    const Color(0xFFFF9800),
    const Color(0xFF00BCD4),
    const Color(0xFF607D8B),
    const Color(0xFF9E9E9E),
    const Color(0xFFE91E63),
  ];

  // When type changes, auto-set icon and color to the type's default
  void onTypeSelected(AccountType type) {
    typeValue.value = type.label;
    selectedIconCode.value = type.icon.codePoint;
    selectedColorVal.value = type.defaultColorVal;
  }

  @override
  void onInit() {
    super.onInit();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    final data = await DatabaseHelper.instance.readAllAccounts();

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var acc in data) {
      final type = acc['type'] as String? ?? 'Lainnya';
      if (!grouped.containsKey(type)) {
        grouped[type] = [];
      }
      grouped[type]!.add({
        'id': acc['id'],
        'name': acc['name'],
        'type': type,
        'balance': acc['balance'],
        'icon_code': acc['icon_code'] as int? ?? Icons.payments_outlined.codePoint,
        'color_val': acc['color_val'] as int? ?? 0xFFFFCA28,
        'is_excluded': (acc['is_excluded'] as int? ?? 0) == 1,
      });
    }

    final newGroups = <Map<String, dynamic>>[];
    grouped.forEach((key, value) {
      newGroups.add({'groupName': key, 'accounts': value});
    });

    accountGroups.value = newGroups;
  }

  void startEditAccount(Map<String, dynamic> acc) {
    editingId.value = acc['id'] as int;
    accountName.value = acc['name'] as String;
    typeValue.value = acc['type'] as String;
    balance.value = acc['balance'] as int;
    excludeFromTotal.value = acc['is_excluded'] as bool? ?? false;
    selectedIconCode.value = acc['icon_code'] as int? ?? Icons.payments_outlined.codePoint;
    selectedColorVal.value = acc['color_val'] as int? ?? 0xFFFFCA28;
  }

  void resetForm() {
    editingId.value = null;
    accountName.value = '';
    typeValue.value = 'Kas Tunai';
    balance.value = 0;
    excludeFromTotal.value = false;
    selectedIconCode.value = Icons.payments_outlined.codePoint;
    selectedColorVal.value = 0xFFFFCA28;
  }

  Future<void> saveAccount() async {
    if (accountName.value.trim().isEmpty) {
      Get.snackbar('Gagal', 'Nama rekening tidak boleh kosong',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1E1E1E),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16));
      return;
    }

    final data = {
      'name': accountName.value.trim(),
      'type': typeValue.value,
      'balance': balance.value,
      'icon_code': selectedIconCode.value,
      'color_val': selectedColorVal.value,
      'is_excluded': excludeFromTotal.value ? 1 : 0,
    };

    if (isEditMode) {
      await DatabaseHelper.instance.updateAccount(editingId.value!, data);
      Get.back();
      Get.snackbar('Berhasil', 'Rekening berhasil diperbarui',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade800,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16));
    } else {
      await DatabaseHelper.instance.insertAccount(data);
      Get.back();
      Get.snackbar('Berhasil', '${accountName.value.trim()} berhasil ditambahkan',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade800,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16));
    }

    resetForm();
    loadAccounts();
  }

  Future<void> deleteAccount(int id, String name) async {
    Get.defaultDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: 'Hapus Rekening',
      titleStyle: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold),
      middleText:
          'Hapus rekening "$name"? Transaksi yang sudah tercatat tidak akan terhapus.',
      middleTextStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      radius: 8,
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        onPressed: () async {
          await DatabaseHelper.instance.deleteAccount(id);
          Get.back();
          loadAccounts();
          Get.snackbar('Berhasil', 'Rekening "$name" telah dihapus',
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(16));
        },
        child: const Text('Hapus', style: TextStyle(color: Colors.white)),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Batal', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
