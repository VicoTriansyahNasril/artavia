import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/database/transaction_store.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/core/utils/calc_engine.dart';
import 'package:artavia/core/utils/transfer_math.dart';
import 'package:artavia/widgets/kobalt/keypad.dart';

/// Which field the Catat keypad fills while on the Transfer segment.
enum TransferField { amount, fee }

/// Transfer segment of Catat (US3). The amount is owned by Catat and shared
/// through [amount] so switching segments keeps it (FR-006); this
/// controller adds the account pair, the remembered admin fee (FR-011),
/// who pays it (FR-012) and the live preview (FR-013).
class TransferController extends GetxController {
  TransferController(this.amount);

  final RxInt amount;

  final accounts = <Map<String, dynamic>>[].obs;
  final sourceId = RxnInt();
  final destId = RxnInt();

  final fee = 0.obs;
  final bearer = FeeBearer.sender.obs;

  /// Fee remembered for the current pair (history-icon chip).
  final remembered = Rxn<FeePref>();

  /// "Isi sendiri" turns the chips into an active fee field.
  final customFee = false.obs;
  final activeField = TransferField.amount.obs;
  final _feeCalc = CalcEngine();

  /// Amount to preload into Catat when editing (set by [attach]).
  int editAmount = 0;
  bool _editing = false;

  TransferFeeMemory get _memory => TransferFeeMemory(
      SettingsService.to.get, (k, v) => SettingsService.to.set(k, v));

  bool get editingFee => activeField.value == TransferField.fee;

  int balanceOf(int? id) =>
      accounts.firstWhereOrNull((a) => a['id'] == id)?['balance'] as int? ?? 0;

  String nameOf(int? id) =>
      accounts.firstWhereOrNull((a) => a['id'] == id)?['name'] as String? ??
      '—';

  TransferPreview get preview => TransferMath.preview(
        amount: amount.value,
        fee: fee.value,
        bearer: bearer.value,
        sourceBalance: balanceOf(sourceId.value),
      );

  bool get canSave =>
      sourceId.value != null &&
      destId.value != null &&
      sourceId.value != destId.value &&
      preview.isValid;

  List<int> get feeChips => TransferFeeMemory.quickChips(remembered.value);

  /// Gives the controller its accounts; selects the edited pair or a
  /// sensible default (preferred source, next account as destination).
  void attach(
    List<Map<String, dynamic>> available, {
    Map? editArgs,
    int? preferredSourceId,
  }) {
    accounts.assignAll(available);
    if (editArgs != null) {
      _editing = true;
      final stored = editArgs['amount'] as int? ?? 0;
      final storedFee = editArgs['admin_fee'] as int? ?? 0;
      final storedBearer = FeeBearer.fromDb(editArgs['admin_fee_type']);
      // Legacy rows keep the fee inside the transfer; the form amount is
      // what left the source before the fee (Penerima: stored + fee).
      editAmount =
          storedBearer == FeeBearer.receiver ? stored + storedFee : stored;
      sourceId.value = editArgs['account_id'] as int?;
      destId.value = editArgs['destination_account_id'] as int?;
      fee.value = storedFee;
      bearer.value = storedBearer;
      remembered.value = _memory.read(sourceId.value ?? -1, destId.value ?? -1);
      return;
    }
    if (accounts.isEmpty) return;
    final ids = accounts.map((a) => a['id'] as int).toList();
    final src = ids.contains(sourceId.value)
        ? sourceId.value!
        : ids.contains(preferredSourceId)
            ? preferredSourceId!
            : ids.first;
    sourceId.value = src;
    if (!ids.contains(destId.value) || destId.value == src) {
      destId.value = ids.firstWhereOrNull((id) => id != src);
    }
    _applyMemory();
  }

  // ─── Pair ────────────────────────────────────────────────────────────────

  /// Picking the account already on the other side swaps them (from ≠ to).
  void setSource(int id) {
    if (id == destId.value) {
      swap();
      return;
    }
    sourceId.value = id;
    _applyMemory();
  }

  void setDestination(int id) {
    if (id == sourceId.value) {
      swap();
      return;
    }
    destId.value = id;
    _applyMemory();
  }

  void swap() {
    final s = sourceId.value;
    sourceId.value = destId.value;
    destId.value = s;
    _applyMemory();
  }

  /// FR-011: preselect the fee last used for this ordered pair.
  void _applyMemory() {
    final s = sourceId.value, d = destId.value;
    if (s == null || d == null) return;
    final pref = _memory.read(s, d);
    remembered.value = pref;
    if (_editing) return;
    fee.value = pref?.fee ?? 0;
    bearer.value = pref?.bearer ?? FeeBearer.sender;
    customFee.value = false;
    activeField.value = TransferField.amount;
  }

  // ─── Fee ─────────────────────────────────────────────────────────────────

  void pickFee(int value) {
    fee.value = value;
    customFee.value = false;
    activeField.value = TransferField.amount;
  }

  void startCustomFee() {
    customFee.value = true;
    activeField.value = TransferField.fee;
    _feeCalc.setValue(fee.value);
  }

  void focusAmount() => activeField.value = TransferField.amount;

  void focusFee() {
    if (customFee.value) activeField.value = TransferField.fee;
  }

  /// Keypad input while the fee field is active: digits only.
  void pressFeeKey(String key) {
    if (KeypadKey.operators.contains(key)) return;
    _feeCalc.press(key);
    fee.value = _feeCalc.result;
  }

  void setBearer(FeeBearer value) => bearer.value = value;

  // ─── Save ────────────────────────────────────────────────────────────────

  /// Writes the transfer (+ fee expense) and remembers the fee for the pair.
  Future<String?> save({
    required String note,
    required DateTime date,
    int? replaceId,
  }) async {
    final p = preview;
    final s = sourceId.value!, d = destId.value!;
    await DatabaseHelper.instance.saveTransfer(
      {
        'type': 'transfer',
        'amount': p.destDelta,
        'category_id': null,
        'note': note,
        'account_id': s,
        'destination_account_id': d,
        'date': date.toIso8601String(),
        'admin_fee': 0,
        'admin_fee_type': null,
      },
      fee: p.fee,
      replaceId: replaceId,
    );
    await _memory.write(s, d, FeePref(p.fee, bearer.value));
    return null;
  }
}
