import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/core/utils/transfer_math.dart';
import 'package:artavia/page/add_transaction/add_transaction_controller.dart';

import 'db_test_helper.dart';

final db = DatabaseHelper.instance;

Future<AddTransactionController> _openCatat({String? tab}) async {
  Get.delete<AddTransactionController>(force: true);
  final c = Get.put(AddTransactionController(initialTab: tab));
  while (c.isLoading.value) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  return c;
}

void _type(AddTransactionController c, String keys) {
  for (final k in keys.split(' ')) {
    c.onKey(k);
  }
}

Future<int> _balance(int id) async =>
    (await db.readAllAccounts()).firstWhere((a) => a['id'] == id)['balance']
        as int;

void main() {
  late int bca, gopay;

  setUpAll(() async {
    await initTestDatabaseFactory();
    Get.testMode = true;
  });

  setUp(() async {
    await db.resetDatabase();
    bca = await db
        .insertAccount({'name': 'BCA', 'type': 'Bank', 'balance': 1000000});
    gopay = await db.insertAccount(
        {'name': 'GoPay', 'type': 'Dompet Digital', 'balance': 0});
    Get.reset();
    await Get.putAsync(() => SettingsService().init());
    Get.put(PeriodService());
  });

  test('expense via keypad: expression result is saved, account remembered',
      () async {
    final c = await _openCatat();
    expect(c.canSave, isFalse);
    _type(c, '4 5 000 + 1 2 5 0 0');
    expect(c.amount.value, 57500);
    expect(c.expression.value, '45.000 + 12.500');
    c.selectAccount(gopay);
    c.selectCategory(c.gridCategories.first['id'] as int);
    expect(c.gridCategories.length, lessThanOrEqualTo(10));

    await c.save();

    final tx = (await db.readAllTransactions()).single;
    expect(tx['type'], 'pengeluaran');
    expect(tx['amount'], 57500);
    expect(await _balance(gopay), -57500);
    expect(SettingsService.to.lastAccountId, gopay);

    // FR-010: the next Catat opens on the last used account.
    final next = await _openCatat();
    expect(next.selectedAccountId.value, gopay);
  });

  test('result ≤ 0 disables Simpan and shows the error', () async {
    final c = await _openCatat();
    _type(c, '4 5 000 - 5 0 000');
    expect(c.amount.value, -5000);
    expect(c.canSave, isFalse);
    expect(c.amountError, 'Jumlah harus lebih dari 0');
  });

  test('typed amount survives switching to Transfer', () async {
    final c = await _openCatat();
    _type(c, '4 5 000');
    c.onTabChanged('Transfer');
    expect(c.transfer.amount.value, 45000);
    expect(c.transfer.sourceId.value, isNot(c.transfer.destId.value));
  });

  test('transfer with fee: balances, Biaya admin expense, fee remembered',
      () async {
    final c = await _openCatat(tab: 'Transfer');
    final t = c.transfer;
    t.setSource(bca);
    t.setDestination(gopay);
    expect(t.fee.value, 0, reason: 'nothing remembered yet');
    _type(c, '1 0 0 000');
    t.pickFee(2500);
    expect(t.preview.sourceDelta, -102500);

    await c.save();

    expect(await _balance(bca), 1000000 - 102500);
    expect(await _balance(gopay), 100000);
    final rows = await db.readAllTransactions();
    final transfer = rows.firstWhere((r) => r['type'] == 'transfer');
    final feeRow = rows.firstWhere((r) => r['type'] == 'pengeluaran');
    expect(transfer['amount'], 100000);
    expect(transfer['admin_fee'], 0);
    expect(feeRow['amount'], 2500);
    expect(feeRow['categoryName'], 'Biaya admin');
    expect(feeRow['account_id'], bca);

    // SC-003: same pair → fee preselected without any extra tap.
    final again = await _openCatat(tab: 'Transfer');
    again.transfer.setSource(bca);
    again.transfer.setDestination(gopay);
    expect(again.transfer.fee.value, 2500);
    expect(again.transfer.feeChips.first, 2500);
  });

  test('receiver pays: destination gets amount − fee, source −amount',
      () async {
    final c = await _openCatat(tab: 'Transfer');
    final t = c.transfer;
    t.setSource(bca);
    t.setDestination(gopay);
    _type(c, '1 0 0 000');
    t.startCustomFee();
    _type(c, '4 000');
    expect(t.fee.value, 4000);
    expect(c.amount.value, 100000, reason: 'keypad filled the fee');
    t.setBearer(FeeBearer.receiver);

    await c.save();

    expect(await _balance(bca), 1000000 - 100000);
    expect(await _balance(gopay), 96000);
  });

  test('picking the other side swaps the pair (from ≠ to)', () async {
    final c = await _openCatat(tab: 'Transfer');
    final t = c.transfer;
    t.setSource(bca);
    t.setDestination(gopay);
    t.setSource(gopay);
    expect(t.sourceId.value, gopay);
    expect(t.destId.value, bca);
  });
}
