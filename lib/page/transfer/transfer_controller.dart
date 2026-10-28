import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/database/transaction_store.dart';
import 'package:artavia/core/services/sound_service.dart';
import 'package:artavia/core/utils/data_refresh.dart';
import 'package:artavia/widgets/components/app_feedback.dart';

/// Transfer between accounts. "source" is what leaves the sender (incl. the
/// admin fee), "dest" is what the receiver gets; fee = source − dest.
class TransferController extends GetxController {
  static const _maxDigits = 12;

  final sourceAmountStr = '0'.obs;
  final destAmountStr = '0'.obs;
  final activeField = 'source'.obs;
  final isSynced = true.obs;

  final isNumpadVisible = false.obs;

  void toggleNumpad() {
    isNumpadVisible.value = !isNumpadVisible.value;
  }

  final sourceAccountId = RxnInt();
  final sourceAccountName = ''.obs;
  final destinationAccountId = RxnInt();
  final destinationAccountName = ''.obs;
  final availableAccounts = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;

  final selectedDate = DateTime.now().obs;

  /// Id of the transfer being edited (FR-017); null when creating.
  int? editId;
  bool get isEdit => editId != null;

  /// Read once from the route, before the async init finishes.
  final bool isEditArgs = Get.arguments?['isEdit'] == true;

  int get sourceAccountBalance => _balanceOf(sourceAccountId.value);
  int get destinationAccountBalance => _balanceOf(destinationAccountId.value);

  int _balanceOf(int? id) {
    final account = availableAccounts.firstWhereOrNull((a) => a['id'] == id);
    return account?['balance'] as int? ?? 0;
  }

  final noteTextController = TextEditingController();
  final note = ''.obs;
  final noteHistory = <String>[].obs;
  final RxBool isWorking = false.obs;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    isLoading.value = true;
    availableAccounts.value = await DatabaseHelper.instance.readAllAccounts();
    final args = Get.arguments;
    if (args != null && args['isEdit'] == true) {
      _fillFromArgs(args as Map);
    } else if (availableAccounts.isNotEmpty) {
      _select(true, availableAccounts.first['id'] as int);
      _select(false,
          availableAccounts[availableAccounts.length > 1 ? 1 : 0]['id'] as int);
    }
    isLoading.value = false;
  }

  void _fillFromArgs(Map args) {
    editId = int.tryParse('${args['id']}');
    final received = args['amount'] as int? ?? 0;
    final fee = args['admin_fee'] as int? ?? 0;
    final senderPaysFee = (args['admin_fee_type'] ?? 'Pengirim') == 'Pengirim';
    destAmountStr.value = '${senderPaysFee ? received : received - fee}';
    sourceAmountStr.value = '${senderPaysFee ? received + fee : received}';
    isSynced.value = fee == 0;
    _select(true, args['account_id'] as int?);
    _select(false, args['destination_account_id'] as int?);
    note.value = args['note'] as String? ?? '';
    noteTextController.text = note.value;
    if (args['date'] is DateTime) selectedDate.value = args['date'] as DateTime;
    isNumpadVisible.value = true;
  }

  void selectAccount(bool isSource, Map<String, dynamic> account) =>
      _select(isSource, account['id'] as int);

  void _select(bool isSource, int? id) {
    final acc = availableAccounts.firstWhereOrNull((a) => a['id'] == id);
    if (acc == null) return;
    if (isSource) {
      sourceAccountId.value = acc['id'] as int;
      sourceAccountName.value = acc['name'] as String;
    } else {
      destinationAccountId.value = acc['id'] as int;
      destinationAccountName.value = acc['name'] as String;
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
    switch (key) {
      case 'delete':
        _editActive((s) => s.length > 1 ? s.substring(0, s.length - 1) : '0');
      case 'C':
        sourceAmountStr.value = '0';
        destAmountStr.value = '0';
        isSynced.value = true;
        activeField.value = 'source';
      case 'confirm':
        await _handleConfirm();
      case '+' || '-':
        break; // operators are not supported for transfers
      default:
        _editActive((s) => s == '0' ? key : s + key);
    }
  }

  /// Applies [change] to the active amount and mirrors it while synced.
  void _editActive(String Function(String current) change) {
    final isSource = activeField.value == 'source';
    final target = isSource ? sourceAmountStr : destAmountStr;
    final next = (int.tryParse(change(target.value)) ?? 0).toString();
    if (next.length > _maxDigits) {
      AppToast.warning('Batas Maksimal', 'Maksimal $_maxDigits digit angka');
      return;
    }
    target.value = next;
    if (isSource && isSynced.value) destAmountStr.value = next;
  }

  String? _validationError(int sent, int received) {
    if (sourceAccountId.value == null || destinationAccountId.value == null) {
      return 'Pilih rekening asal dan tujuan';
    }
    if (sourceAccountId.value == destinationAccountId.value) {
      return 'Rekening asal dan tujuan tidak boleh sama';
    }
    if (sent <= 0 || received <= 0) return 'Nominal tidak boleh 0';
    if (sent < received) {
      return 'Nominal dikirim tidak boleh lebih kecil dari yang diterima';
    }
    return null;
  }

  Future<void> _handleConfirm() async {
    if (isWorking.value) return;
    final sent = int.tryParse(sourceAmountStr.value) ?? 0;
    final received = int.tryParse(destAmountStr.value) ?? 0;
    final error = _validationError(sent, received);
    if (error != null) {
      AppToast.warning('Peringatan', error);
      return;
    }

    if (note.value.isNotEmpty && !noteHistory.contains(note.value)) {
      noteHistory.insert(0, note.value);
    }

    // The receiver gets `amount`; the sender also pays the fee.
    final row = {
      'type': 'transfer',
      'amount': received,
      'category_id': null,
      'note': note.value,
      'account_id': sourceAccountId.value,
      'destination_account_id': destinationAccountId.value,
      'date': selectedDate.value.toIso8601String(),
      'admin_fee': sent - received,
      'admin_fee_type': 'Pengirim',
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
      if (isEdit) {
        Get.until((route) => route.isFirst);
      } else {
        Get.back();
      }
      AppToast.success(
          isEdit ? 'Diperbarui' : 'Berhasil',
          isEdit
              ? 'Transfer berhasil diperbarui'
              : 'Transfer berhasil disimpan');
    } catch (e) {
      AppToast.error('Gagal', 'Transfer tidak dapat disimpan');
    } finally {
      isWorking.value = false;
    }
  }

  void onSuggestionTapped(String suggestion) {
    noteTextController.text = suggestion;
    note.value = suggestion;
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked == null) return;
    final now = DateTime.now();
    selectedDate.value =
        DateTime(picked.year, picked.month, picked.day, now.hour, now.minute);
  }
}
