import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/transaction/transaction_item.dart';

/// Read-only view of one transaction; arguments come from [transactionArgs].
class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> arg =
        Map<String, dynamic>.from(Get.arguments ?? {});
    final type = arg['type'] as String? ?? 'pengeluaran';
    final isExpense = type == 'pengeluaran';
    final isTransfer = type == 'transfer';
    final amount = arg['amount'] as int? ?? 0;
    final adminFee = arg['admin_fee'] as int? ?? 0;
    final note = arg['note'] as String? ?? '';
    final date = arg['date'] as DateTime? ?? DateTime.now();
    final category =
        isTransfer ? 'Transfer' : (arg['category'] as String? ?? 'Lainnya');
    final color = arg['color_val'] != null
        ? Color(arg['color_val'] as int)
        : (isExpense ? colorExpense : colorIncome);
    final amountColor = isTransfer
        ? colorText
        : isExpense
            ? colorExpense
            : colorIncome;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => openTransactionEditor(arg),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
                color: colorCard, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: color.withValues(alpha: 0.14),
                  child: CategoryIcon(
                    iconCode: arg['icon_code'] as int? ??
                        (isExpense
                            ? Icons.arrow_upward.codePoint
                            : Icons.arrow_downward.codePoint),
                    iconPath: arg['icon_path'] as String?,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(category,
                    style: const TextStyle(color: colorGrey, fontSize: 14)),
                const SizedBox(height: 6),
                Text(
                  '${isExpense ? '-' : isTransfer ? '' : '+'}${CurrencyService.to.format(amount)}',
                  style: TextStyle(
                      color: amountColor,
                      fontSize: 30,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: colorCard,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: _rows(arg, isTransfer, adminFee, date, note)
                  .expand((w) => [const Divider(indent: 16), w])
                  .skip(1)
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              final deleted = await confirmDeleteTransaction(arg['id'] as int?);
              if (deleted) Get.back();
            },
            icon: const Icon(Icons.delete_outline, color: colorExpense),
            label: const Text('Hapus Transaksi',
                style: TextStyle(color: colorExpense)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: BorderSide(color: colorExpense.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _rows(Map<String, dynamic> arg, bool isTransfer, int adminFee,
      DateTime date, String note) {
    final account = arg['account'] as String? ?? '-';
    return [
      _row(Icons.account_balance_wallet_outlined,
          isTransfer ? 'Dari' : 'Rekening', account),
      if (isTransfer)
        _row(Icons.call_received_rounded, 'Ke',
            arg['destination_account'] as String? ?? '-'),
      if (isTransfer && adminFee > 0)
        _row(Icons.receipt_outlined, 'Biaya admin',
            CurrencyService.to.format(adminFee)),
      _row(Icons.calendar_today_outlined, 'Tanggal',
          DateFormat('EEEE, d MMMM yyyy · HH:mm', 'id_ID').format(date)),
      if (note.isNotEmpty) _row(Icons.notes_rounded, 'Catatan', note),
    ];
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorGrey, size: 18),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(color: colorGrey, fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: colorText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
