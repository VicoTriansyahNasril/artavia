import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/models/account_model.dart';
import 'package:artavia/core/utils/data_refresh.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/components/tutorial_card.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/// Defines account type metadata for the type selector grid
class AccountType {
  final String label;
  final IconData icon;
  final int defaultColorVal;

  const AccountType({
    required this.label,
    required this.icon,
    required this.defaultColorVal,
  });

  int get defaultIconCode => icon.codePoint;
}

class AccountManagementController extends GetxController {
  final accountGroups = <Map<String, dynamic>>[].obs;
  
  final GlobalKey keyAccountFAB = GlobalKey();
  final GlobalKey keyAddAccountForm = GlobalKey();
  final GlobalKey keyAddAccountSave = GlobalKey();

  // ─── Account Types ─────────────────────────────────────────────────────────

  static const List<AccountType> accountTypes = [
    AccountType(
      label: 'Kas Tunai',
      icon: Icons.payments,
      defaultColorVal: 0xFFF5C842,
    ),
    AccountType(
      label: 'Bank',
      icon: Icons.account_balance,
      defaultColorVal: 0xFF64B5F6,
    ),
    AccountType(
      label: 'Kartu Kredit',
      icon: Icons.credit_card,
      defaultColorVal: 0xFFE57373,
    ),
    AccountType(
      label: 'Dompet Digital',
      icon: Icons.phone_android,
      defaultColorVal: 0xFF81C784,
    ),
    AccountType(
      label: 'Tabungan',
      icon: Icons.savings,
      defaultColorVal: 0xFF4DB6AC,
    ),
    AccountType(
      label: 'Investasi',
      icon: Icons.trending_up,
      defaultColorVal: 0xFFBA68C8,
    ),
    AccountType(
      label: 'Pinjaman',
      icon: Icons.account_balance_wallet,
      defaultColorVal: 0xFFFFB74D,
    ),
    AccountType(
      label: 'Investasi Aset',
      icon: Icons.real_estate_agent,
      defaultColorVal: 0xFF90A4AE,
    ),
    AccountType(
      label: 'Lainnya',
      icon: Icons.more_horiz,
      defaultColorVal: 0xFF8A8A8E,
    ),
  ];

  static const List<String> keuanganIcons = AppIcons.keuangan;

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

  final RxBool isWorking = false.obs;

  final selectedIconCode = Rx<int?>(Icons.payments_outlined.codePoint);
  final selectedIconPath = Rx<String?>(null);
  final selectedColorVal = 0xFFF5C842.obs;

  // Edit mode
  final editingId = Rx<int?>(null);
  bool get isEditMode => editingId.value != null;

  final nameController = TextEditingController();
  final balanceController = TextEditingController();

  // ─── Actions ─────────────────────────────────────────────────────────────

  void onTypeSelected(AccountType type) {
    typeValue.value = type.label;
    selectedIconCode.value = type.defaultIconCode;
    selectedIconPath.value = null;
    selectedColorVal.value = type.defaultColorVal;
  }

  void onIconSelected(String path) {
    selectedIconPath.value = path;
    selectedIconCode.value = null;
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



  @override
  void onClose() {
    nameController.dispose();
    balanceController.dispose();
    super.onClose();
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
        'icon_path': account.iconPath,
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
    selectedIconPath.value = acc['icon_path'] as String?;
    selectedColorVal.value = acc['color_val'] as int? ?? 0xFFF5C842;
    
    nameController.text = accountName.value;
    balanceController.text = balance.value == 0 ? '' : balance.value.toString();
  }

  void resetForm() {
    editingId.value = null;
    accountName.value = '';
    typeValue.value = 'Kas Tunai';
    balance.value = 0;
    currencyCode.value = 'IDR';
    excludeFromTotal.value = false;
    selectedIconCode.value = Icons.payments_outlined.codePoint;
    selectedIconPath.value = null;
    selectedColorVal.value = 0xFFF5C842;

    nameController.clear();
    balanceController.clear();
  }

  Future<void> saveAccount() async {
    if (isWorking.value) return;
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

    isWorking.value = true;
    try {
      final account = AccountModel(
        id: editingId.value,
        name: name,
        type: typeValue.value,
        balance: balance.value,
        currencyCode: currencyCode.value,
        iconCode: selectedIconCode.value ?? Icons.payments_outlined.codePoint,
        iconPath: selectedIconPath.value,
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
      refreshAllGlobalData();
    } finally {
      isWorking.value = false;
    }
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
          if (isWorking.value) return;
          isWorking.value = true;
          try {
            await DatabaseHelper.instance.deleteAccount(id);
            Get.back();
            loadAccounts();
            refreshAllGlobalData();
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
          } finally {
            isWorking.value = false;
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

  bool _hasShownMainTutorial = false;

  Future<void> showTutorialIfNoAccount() async {
    if (_hasShownMainTutorial) return;
    final accounts = await DatabaseHelper.instance.readAllAccounts();
    if (accounts.isEmpty) {
      _hasShownMainTutorial = true;
      _showTutorial();
    }
  }

  void _showTutorial() {
    List<TargetFocus> targets = [
      TargetFocus(
        identify: "TargetAddAccountFAB",
        keyTarget: keyAccountFAB,
        alignSkip: Alignment.topLeft,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return TutorialCard(
                controller: controller,
                title: "Buat Rekening Baru",
                description: "Ketuk tombol ini untuk membuat dompet Tunai, rekening Bank, atau jenis dompet lainnya.",
                isLast: true,
              );
            },
          )
        ],
      )
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      hideSkip: true,
      paddingFocus: 10,
      opacityShadow: 0.8,
    ).show(context: keyAccountFAB.currentContext!);
  }

  bool _hasShownAddTutorial = false;

  Future<void> showAddAccountTutorialIfNoAccount(BuildContext context) async {
    if (_hasShownAddTutorial) return;
    final accounts = await DatabaseHelper.instance.readAllAccounts();
    if (accounts.isEmpty && context.mounted) {
      _hasShownAddTutorial = true;
      _showAddAccountTutorial(context);
    }
  }

  void _showAddAccountTutorial(BuildContext context) {
    List<TargetFocus> targets = [
      TargetFocus(
        identify: "TargetAddAccountForm",
        keyTarget: keyAddAccountForm,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return TutorialCard(
                controller: controller,
                title: "Langkah 1: Isi Detail",
                description: "Mulai dengan mengisi nama rekening (mis: Dompet, BCA) beserta saldo awal Anda saat ini.",
                isLast: false,
              );
            },
          )
        ],
      ),
      TargetFocus(
        identify: "TargetAddAccountSave",
        keyTarget: keyAddAccountSave,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return TutorialCard(
                controller: controller,
                title: "Langkah 2: Simpan",
                description: "Jika sudah, tekan Simpan untuk membuat rekening pertama Anda. Mudah bukan?",
                isLast: true,
              );
            },
          )
        ],
      )
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      hideSkip: true,
      paddingFocus: 10,
      opacityShadow: 0.8,
    ).show(context: context);
  }
}
