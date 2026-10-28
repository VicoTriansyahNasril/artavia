import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/models/account_model.dart';
import 'package:artavia/core/utils/data_refresh.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/components/tutorial_card.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/widgets/components/app_feedback.dart';
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
      defaultColorVal: 0xFFE0B25C,
    ),
    AccountType(
      label: 'Bank',
      icon: Icons.account_balance,
      defaultColorVal: 0xFF5FA8D3,
    ),
    AccountType(
      label: 'Kartu Kredit',
      icon: Icons.credit_card,
      defaultColorVal: 0xFFE07A7A,
    ),
    AccountType(
      label: 'Dompet Digital',
      icon: Icons.phone_android,
      defaultColorVal: 0xFF5FBF8F,
    ),
    AccountType(
      label: 'Tabungan',
      icon: Icons.savings,
      defaultColorVal: 0xFF4FB6B0,
    ),
    AccountType(
      label: 'Investasi',
      icon: Icons.trending_up,
      defaultColorVal: 0xFF9D8CE6,
    ),
    AccountType(
      label: 'Pinjaman',
      icon: Icons.account_balance_wallet,
      defaultColorVal: 0xFFE59A6B,
    ),
    AccountType(
      label: 'Investasi Aset',
      icon: Icons.real_estate_agent,
      defaultColorVal: 0xFF8D94A3,
    ),
    AccountType(
      label: 'Lainnya',
      icon: Icons.more_horiz,
      defaultColorVal: 0xFF8D94A3,
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

  final presetColors = categoryPalette;

  // ─── Form State ──────────────────────────────────────────────────────────

  final typeValue = 'Kas Tunai'.obs;
  final accountName = ''.obs;
  final balance = 0.obs;
  final currencyCode = 'IDR'.obs;
  final excludeFromTotal = false.obs;

  final RxBool isWorking = false.obs;

  final selectedIconCode = Rx<int?>(Icons.payments_outlined.codePoint);
  final selectedIconPath = Rx<String?>(null);
  final selectedColorVal = categoryPalette[2].toARGB32().obs;

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

  /// Opens the add/edit form from anywhere (Aset tab, Kelola Rekening) with a
  /// clean or pre-filled form. [account] is a raw `accounts` row or a row from
  /// [accountGroups].
  static Future<void> openEditor([Map<String, dynamic>? account]) async {
    if (!Get.isRegistered<AccountManagementController>()) {
      Get.put(AccountManagementController());
    }
    final c = Get.find<AccountManagementController>();
    if (account == null) {
      c.resetForm();
    } else {
      final excluded = account['is_excluded'];
      c.startEditAccount({
        ...account,
        'is_excluded': excluded == true || excluded == 1,
      });
    }
    await Get.toNamed(addAccountRoute);
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
    selectedColorVal.value =
        acc['color_val'] as int? ?? categoryPalette[2].toARGB32();

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
    selectedColorVal.value = categoryPalette[2].toARGB32();

    nameController.clear();
    balanceController.clear();
  }

  Future<void> saveAccount() async {
    if (isWorking.value) return;
    final name = accountName.value.trim();
    if (name.isEmpty) {
      AppToast.warning('Gagal', 'Nama rekening tidak boleh kosong');
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
        await DatabaseHelper.instance
            .updateAccount(editingId.value!, account.toJson()..remove('id'));
        Get.back();
        _showSuccessSnack(
            'Rekening diperbarui', '${account.name} berhasil diperbarui');
      } else {
        await DatabaseHelper.instance
            .insertAccount(account.toJson()..remove('id'));
        Get.back();
        _showSuccessSnack(
            'Rekening ditambahkan', '${account.name} berhasil ditambahkan');
      }

      resetForm();
      loadAccounts();
      refreshAllGlobalData();
    } finally {
      isWorking.value = false;
    }
  }

  Future<void> deleteAccount(int id, String name) async {
    final ok = await AppDialog.confirm(
      title: 'Hapus Rekening',
      message: 'Hapus "$name"? Rekening yang sudah memiliki riwayat transaksi '
          'tidak dapat dihapus. Transaksi berulang yang memakai rekening ini '
          'ikut terhapus.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!ok || isWorking.value) return;
    isWorking.value = true;
    try {
      await DatabaseHelper.instance.deleteAccount(id);
      loadAccounts();
      refreshAllGlobalData();
      AppToast.success('Berhasil', '"$name" telah dihapus');
    } catch (e) {
      AppToast.error('Tidak Dapat Dihapus',
          'Rekening ini masih memiliki riwayat transaksi.');
    } finally {
      isWorking.value = false;
    }
  }

  void _showSuccessSnack(String title, String message) =>
      AppToast.success(title, message);

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
                description:
                    "Ketuk tombol ini untuk membuat dompet Tunai, rekening Bank, atau jenis dompet lainnya.",
                isLast: true,
              );
            },
          )
        ],
      )
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: colorScrim,
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
                description:
                    "Mulai dengan mengisi nama rekening (mis: Dompet, BCA) beserta saldo awal Anda saat ini.",
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
                description:
                    "Jika sudah, tekan Simpan untuk membuat rekening pertama Anda. Mudah bukan?",
                isLast: true,
              );
            },
          )
        ],
      )
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: colorScrim,
      hideSkip: true,
      paddingFocus: 10,
      opacityShadow: 0.8,
    ).show(context: context);
  }
}
