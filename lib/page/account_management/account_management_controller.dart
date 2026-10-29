import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/database/transaction_store.dart';
import 'package:artavia/core/models/account_model.dart';
import 'package:artavia/core/utils/data_refresh.dart';
import 'package:artavia/core/utils/finance_calc.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/components/app_feedback.dart';

/// One collapsible Rekening group with its subtotal.
class AccountGroupView {
  final String name;
  final List<Map<String, dynamic>> accounts;
  final int subtotal;

  const AccountGroupView(this.name, this.accounts, this.subtotal);
}

/// Rekening tab + account form (FR-020, FR-021).
class AccountManagementController extends GetxController {
  /// Account types offered in the form (stored as `accounts.type`).
  static const accountTypes = [
    'Kas Tunai',
    'Bank',
    'Dompet Digital',
    'Tabungan',
    'Kartu Kredit',
    'Pinjaman',
    'Investasi',
    'Investasi Aset',
    'Lainnya',
  ];

  // ─── List state ──────────────────────────────────────────────────────────

  final groups = <AccountGroupView>[].obs;
  final archived = <Map<String, dynamic>>[].obs;
  final collapsed = <String>{}.obs;
  final worth = const NetWorth(0, 0).obs;
  final isLoading = false.obs;

  // ─── Form state ──────────────────────────────────────────────────────────

  final editingId = RxnInt();
  bool get isEditMode => editingId.value != null;
  final typeValue = 'Kas Tunai'.obs;
  final accountName = ''.obs;
  final balance = 0.obs;
  final currencyCode = 'IDR'.obs;
  final excludeFromTotal = false.obs;
  final iconKey = IconRegistry.accountTypeKey('Kas Tunai').obs;
  final colorVal = categoryPaletteValues[7].obs;
  final creditLimit = 0.obs;
  final dueDay = RxnInt();
  final isWorking = false.obs;

  /// Bumped whenever the form is (re)filled so text fields reset.
  final formVersion = 0.obs;

  bool get isCreditCard => typeValue.value == 'Kartu Kredit';

  @override
  void onInit() {
    super.onInit();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    isLoading.value = true;
    try {
      final rows = await DatabaseHelper.instance.readAllAccounts();
      final active = rows.where((a) => a['is_archived'] != 1).toList();
      archived.value = rows.where((a) => a['is_archived'] == 1).toList();
      worth.value = computeNetWorth(active);
      groups.value = [
        for (final g in accountGroups)
          if (active.any((a) => accountGroup(a['type'] as String?) == g))
            () {
              final list = active
                  .where((a) => accountGroup(a['type'] as String?) == g)
                  .toList();
              return AccountGroupView(g, list, computeNetWorth(list).net);
            }(),
      ];
    } finally {
      isLoading.value = false;
    }
  }

  void toggleGroup(String name) {
    if (!collapsed.remove(name)) collapsed.add(name);
  }

  // ─── Archive / delete ────────────────────────────────────────────────────

  Future<void> setArchived(Map<String, dynamic> account, bool value) async {
    await DatabaseHelper.instance
        .updateAccount(account['id'] as int, {'is_archived': value ? 1 : 0});
    await loadAccounts();
    refreshAllGlobalData();
    AppToast.success(value ? 'Diarsipkan' : 'Dipulihkan',
        '${account['name']} ${value ? 'disembunyikan dari pilihan' : 'aktif kembali'}');
  }

  /// FR-021: an account with history offers Arsipkan first.
  Future<void> deleteAccount(Map<String, dynamic> account) async {
    final id = account['id'] as int;
    final name = account['name'] as String;
    final db = DatabaseHelper.instance;
    final count = await db.countAccountTransactions(id);

    if (count == 0) {
      final ok = await AppDialog.confirm(
        icon: LucideIcons.trash2,
        title: 'Hapus $name?',
        message: 'Rekening ini belum punya transaksi dan akan dihapus.',
        confirmLabel: 'Hapus rekening',
        destructive: true,
      );
      if (!ok) return;
      await db.deleteAccount(id);
    } else {
      final choice = await AppDialog.choose(
        icon: LucideIcons.archive,
        title: 'Hapus $name?',
        message: 'Rekening ini punya $count transaksi. Arsipkan agar riwayat '
            'tetap aman dan rekening tidak muncul di pilihan.',
        info: const DialogInfo(
            'Menghapus juga menghapus semua transaksinya dan mengubah saldo '
            'rekening lain yang terkait transfer.',
            warning: true),
        safeLabel: 'Arsipkan',
        dangerLabel: 'Hapus beserta $count transaksi',
      );
      if (choice == DialogChoice.cancel) return;
      if (choice == DialogChoice.safe) {
        await setArchived(account, true);
        _closeFormIfOpen();
        return;
      }
      await db.deleteAccountWithTransactions(id);
    }
    await loadAccounts();
    refreshAllGlobalData();
    _closeFormIfOpen();
    AppToast.success('Dihapus', '$name telah dihapus');
  }

  void _closeFormIfOpen() {
    if (Get.currentRoute == addAccountRoute) Get.back();
  }

  // ─── Form ────────────────────────────────────────────────────────────────

  /// Opens the add/edit form from anywhere with a clean or filled form.
  static Future<void> openEditor([Map<String, dynamic>? account]) async {
    if (!Get.isRegistered<AccountManagementController>()) {
      Get.put(AccountManagementController());
    }
    final c = Get.find<AccountManagementController>();
    if (account == null) {
      c.resetForm();
    } else {
      c._fill(account);
    }
    await Get.toNamed(addAccountRoute);
  }

  void _fill(Map<String, dynamic> row) {
    final a = AccountModel.fromJson(row);
    editingId.value = a.id;
    accountName.value = a.name;
    typeValue.value = a.type;
    balance.value = a.balance;
    currencyCode.value = a.currencyCode;
    excludeFromTotal.value = a.isExcluded;
    iconKey.value = IconRegistry.contains(a.iconKey)
        ? a.iconKey!
        : IconRegistry.accountTypeKey(a.type);
    colorVal.value = nearestPaletteValue(a.colorVal);
    creditLimit.value = a.creditLimit ?? 0;
    dueDay.value = a.dueDay;
    formVersion.value++;
  }

  void resetForm() {
    editingId.value = null;
    accountName.value = '';
    typeValue.value = 'Kas Tunai';
    balance.value = 0;
    currencyCode.value = 'IDR';
    excludeFromTotal.value = false;
    iconKey.value = IconRegistry.accountTypeKey('Kas Tunai');
    colorVal.value = categoryPaletteValues[7];
    creditLimit.value = 0;
    dueDay.value = null;
    formVersion.value++;
  }

  /// Picking a type also suggests its icon unless the user chose one.
  void onTypeSelected(String type) {
    final suggested = IconRegistry.accountTypeKey(typeValue.value);
    typeValue.value = type;
    if (iconKey.value == suggested) {
      iconKey.value = IconRegistry.accountTypeKey(type);
    }
  }

  Future<void> saveAccount() async {
    if (isWorking.value) return;
    final name = accountName.value.trim();
    if (name.isEmpty) {
      AppToast.warning('Nama rekening', 'Nama rekening tidak boleh kosong');
      return;
    }
    isWorking.value = true;
    try {
      final row = {
        'name': name,
        'type': typeValue.value,
        'balance': balance.value,
        'currency_code': currencyCode.value,
        'icon_key': iconKey.value,
        'color_val': colorVal.value,
        'is_excluded': excludeFromTotal.value ? 1 : 0,
        'credit_limit':
            isCreditCard && creditLimit.value > 0 ? creditLimit.value : null,
        'due_day': isCreditCard ? dueDay.value : null,
      };
      final db = DatabaseHelper.instance;
      final editing = isEditMode;
      if (editing) {
        await db.updateAccount(editingId.value!, row);
      } else {
        await db.insertAccount(row);
      }
      Get.back();
      AppToast.success(editing ? 'Rekening diperbarui' : 'Rekening ditambahkan',
          '$name berhasil ${editing ? 'diperbarui' : 'ditambahkan'}');
      resetForm();
      await loadAccounts();
      refreshAllGlobalData();
    } catch (_) {
      AppToast.error('Gagal', 'Rekening tidak dapat disimpan');
    } finally {
      isWorking.value = false;
    }
  }
}
