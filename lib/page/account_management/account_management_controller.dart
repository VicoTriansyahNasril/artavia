import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/models/account_model.dart';

/// Defines account type metadata for the type selector grid
class AccountType {
  final String label;
  final IconData icon;
  final int defaultColorVal;
  final int defaultIconCode;

  const AccountType({
    required this.label,
    required this.icon,
    required this.defaultColorVal,
    required this.defaultIconCode,
  });
}

class AccountManagementController extends GetxController {
  final accountGroups = <Map<String, dynamic>>[].obs;

  // ─── Account Types ─────────────────────────────────────────────────────────

  static const List<AccountType> accountTypes = [
    AccountType(
      label: 'Kas Tunai',
      icon: Icons.payments_outlined,
      defaultColorVal: 0xFFF5C842,
      defaultIconCode: 0xe40f, // payments
    ),
    AccountType(
      label: 'Bank',
      icon: Icons.account_balance_outlined,
      defaultColorVal: 0xFF64B5F6,
      defaultIconCode: 0xe0a9, // account_balance
    ),
    AccountType(
      label: 'Kartu Kredit',
      icon: Icons.credit_card_outlined,
      defaultColorVal: 0xFFE57373,
      defaultIconCode: 0xe1ba, // credit_card
    ),
    AccountType(
      label: 'Dompet Digital',
      icon: Icons.phone_android_outlined,
      defaultColorVal: 0xFF81C784,
      defaultIconCode: 0xe32c, // phone_android
    ),
    AccountType(
      label: 'Tabungan',
      icon: Icons.savings_outlined,
      defaultColorVal: 0xFF4DB6AC,
      defaultIconCode: 0xf05fb, // savings
    ),
    AccountType(
      label: 'Investasi',
      icon: Icons.trending_up_rounded,
      defaultColorVal: 0xFFBA68C8,
      defaultIconCode: 0xe698, // trending_up
    ),
    AccountType(
      label: 'Pinjaman',
      icon: Icons.account_balance_wallet_outlined,
      defaultColorVal: 0xFFFFB74D,
      defaultIconCode: 0xe150, // account_balance_wallet
    ),
    AccountType(
      label: 'Investasi Aset',
      icon: Icons.real_estate_agent_outlined,
      defaultColorVal: 0xFF90A4AE,
      defaultIconCode: 0xf060e, // real_estate_agent
    ),
    AccountType(
      label: 'Lainnya',
      icon: Icons.more_horiz,
      defaultColorVal: 0xFF8A8A8E,
      defaultIconCode: 0xe5d3, // more_horiz
    ),
  ];

  // ─── Curated icon options for the icon picker ─────────────────────────────

  static const List<IconData> iconOptions = [
    // Money / Finance
    Icons.payments_outlined,
    Icons.account_balance_outlined,
    Icons.credit_card_outlined,
    Icons.savings_outlined,
    Icons.trending_up_rounded,
    Icons.account_balance_wallet_outlined,
    Icons.attach_money,
    Icons.currency_exchange,
    Icons.monetization_on_outlined,
    Icons.receipt_long_outlined,
    Icons.real_estate_agent_outlined,
    Icons.store_outlined,
    // Digital / Tech
    Icons.phone_android_outlined,
    Icons.qr_code_scanner_outlined,
    Icons.wifi_outlined,
    Icons.laptop_outlined,
    // Transport
    Icons.directions_car_outlined,
    Icons.flight_outlined,
    Icons.train_outlined,
    // Life
    Icons.home_outlined,
    Icons.medical_services_outlined,
    Icons.school_outlined,
    Icons.shopping_bag_outlined,
    Icons.restaurant_outlined,
    Icons.fitness_center_outlined,
    // Work
    Icons.work_outline,
    Icons.business_center_outlined,
    Icons.bar_chart,
    Icons.analytics_outlined,
    Icons.handshake_outlined,
    // Misc
    Icons.star_outline_rounded,
    Icons.favorite_outline,
    Icons.emoji_events_outlined,
    Icons.card_giftcard_outlined,
    Icons.lock_outline,
    Icons.security,
  ];

  // ─── Supported Currencies ─────────────────────────────────────────────────

  static const List<Map<String, String>> supportedCurrencies = [
    {'code': 'IDR', 'symbol': 'Rp', 'name': 'Rupiah'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'SGD', 'symbol': 'S\$', 'name': 'Sing. Dollar'},
    {'code': 'MYR', 'symbol': 'RM', 'name': 'Ringgit'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Yen'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Aus. Dollar'},
    {'code': 'CNY', 'symbol': '¥', 'name': 'Yuan'},
    {'code': 'SAR', 'symbol': '﷼', 'name': 'Riyal'},
  ];

  // ─── Preset Colors ────────────────────────────────────────────────────────

  final presetColors = <Color>[
    const Color(0xFFF5C842), // Amber
    const Color(0xFF81C784), // Sage green
    const Color(0xFF64B5F6), // Sky blue
    const Color(0xFFE57373), // Rose
    const Color(0xFFBA68C8), // Lavender
    const Color(0xFFFFB74D), // Orange
    const Color(0xFF4DB6AC), // Teal
    const Color(0xFF90A4AE), // Blue-grey
    const Color(0xFFF48FB1), // Pink
    const Color(0xFFA5D6A7), // Light green
    const Color(0xFF80DEEA), // Cyan
    const Color(0xFFEF9A9A), // Salmon
  ];

  // ─── Form State ──────────────────────────────────────────────────────────

  final typeValue = 'Kas Tunai'.obs;
  final accountName = ''.obs;
  final balance = 0.obs;
  final currencyCode = 'IDR'.obs;
  final excludeFromTotal = false.obs;
  final selectedIconCode = Icons.payments_outlined.codePoint.obs;
  final selectedColorVal = 0xFFF5C842.obs;

  // Edit mode
  final editingId = Rx<int?>(null);
  bool get isEditMode => editingId.value != null;

  // ─── Actions ─────────────────────────────────────────────────────────────

  void onTypeSelected(AccountType type) {
    typeValue.value = type.label;
    selectedIconCode.value = type.defaultIconCode;
    selectedColorVal.value = type.defaultColorVal;
  }

  void onIconSelected(IconData icon) {
    selectedIconCode.value = icon.codePoint;
  }

  void onColorSelected(Color color) {
    selectedColorVal.value = color.toARGB32();
  }

  void onCurrencySelected(String code) {
    currencyCode.value = code;
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    final data = await DatabaseHelper.instance.readAllAccounts();

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var row in data) {
      final account = AccountModel.fromJson(row);
      final type = account.type;
      grouped.putIfAbsent(type, () => []).add({
        'id': account.id,
        'name': account.name,
        'type': account.type,
        'balance': account.balance,
        'currency_code': account.currencyCode,
        'icon_code': account.iconCode,
        'color_val': account.colorVal,
        'is_excluded': account.isExcluded,
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
    currencyCode.value = acc['currency_code'] as String? ?? 'IDR';
    excludeFromTotal.value = acc['is_excluded'] as bool? ?? false;
    selectedIconCode.value =
        acc['icon_code'] as int? ?? Icons.payments_outlined.codePoint;
    selectedColorVal.value = acc['color_val'] as int? ?? 0xFFF5C842;
  }

  void resetForm() {
    editingId.value = null;
    accountName.value = '';
    typeValue.value = 'Kas Tunai';
    balance.value = 0;
    currencyCode.value = 'IDR';
    excludeFromTotal.value = false;
    selectedIconCode.value = Icons.payments_outlined.codePoint;
    selectedColorVal.value = 0xFFF5C842;
  }

  Future<void> saveAccount() async {
    final name = accountName.value.trim();
    if (name.isEmpty) {
      Get.snackbar(
        'Gagal',
        'Nama rekening tidak boleh kosong',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1C1C1F),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
      );
      return;
    }

    final account = AccountModel(
      id: editingId.value,
      name: name,
      type: typeValue.value,
      balance: balance.value,
      currencyCode: currencyCode.value,
      iconCode: selectedIconCode.value,
      colorVal: selectedColorVal.value,
      isExcluded: excludeFromTotal.value,
    );

    if (isEditMode) {
      await DatabaseHelper.instance.updateAccount(
          editingId.value!, account.toJson()..remove('id'));
      Get.back();
      _showSuccessSnack('Rekening diperbarui', '${account.name} berhasil diperbarui');
    } else {
      await DatabaseHelper.instance.insertAccount(account.toJson()..remove('id'));
      Get.back();
      _showSuccessSnack('Rekening ditambahkan', '${account.name} berhasil ditambahkan');
    }

    resetForm();
    loadAccounts();
  }

  Future<void> deleteAccount(int id, String name) async {
    Get.defaultDialog(
      backgroundColor: const Color(0xFF1C1C1F),
      title: 'Hapus Rekening',
      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      middleText:
          'Hapus "$name"? Riwayat transaksi tidak akan ikut terhapus.',
      middleTextStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      radius: 16,
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE57373),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () async {
          try {
            await DatabaseHelper.instance.deleteAccount(id);
            Get.back();
            loadAccounts();
            Get.snackbar(
              'Berhasil',
              '"$name" telah dihapus',
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(16),
              borderRadius: 12,
            );
          } catch (e) {
            Get.back();
            Get.snackbar(
              'Tidak Dapat Dihapus',
              'Rekening ini memiliki riwayat transaksi.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFFE57373).withValues(alpha: 0.9),
              colorText: Colors.white,
              margin: const EdgeInsets.all(16),
              borderRadius: 12,
            );
          }
        },
        child: const Text('Hapus', style: TextStyle(color: Colors.white)),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Batal', style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  void _showSuccessSnack(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    );
  }
}
