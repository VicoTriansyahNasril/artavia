import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/model/transaction_model.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/core/utils/data_refresh.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel tx;
  final bool showDate;
  const TransactionItem({super.key, required this.tx, this.showDate = false});

  @override
  Widget build(BuildContext context) {
    final isExpense = tx.type == 'pengeluaran';
    final isTransfer = tx.type == 'transfer';

    Color iconColor;
    int? iconCode;
    String? iconPath;

    if (isTransfer) {
      iconColor = colorGrey;
      iconCode = Icons.swap_horiz.codePoint;
    } else if (tx.categoryColorVal != null && tx.categoryColorVal != 0) {
      iconColor = Color(tx.categoryColorVal!);
      iconCode = tx.categoryIconCode;
      iconPath = tx.categoryIconPath;
      if (iconCode == null && iconPath == null) {
        iconCode = isExpense ? Icons.arrow_upward.codePoint : Icons.arrow_downward.codePoint;
      }
    } else {
      iconColor = isExpense ? colorExpense : colorIncome;
      iconCode = isExpense ? Icons.arrow_upward.codePoint : Icons.arrow_downward.codePoint;
    }

    final iconBg = iconColor.withValues(alpha: 0.15);
    final displayAmount = (tx.amount ?? 0).abs();
    final amountColor = isTransfer ? colorGrey : isExpense ? colorExpense : colorIncome;
    final prefix = isTransfer ? '' : isExpense ? '-' : '+';

    final args = {
      'id': tx.id,
      'type': tx.type,
      'amount': displayAmount,
      'category': tx.categoryName,
      'note': tx.note,
      'account': tx.accountName ?? 'CASH',
      'account_id': tx.accountId,
      'destination_account': tx.destinationAccountName,
      'destination_account_id': tx.destinationAccountId,
      'date': tx.date,
      'icon_code': iconCode,
      'icon_path': iconPath,
      'color_val': iconColor.toARGB32(),
    };

    return Slidable(
      key: ValueKey(tx.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              if (tx.type == 'transfer') {
                Get.toNamed('/transfer', arguments: {'isEdit': true, ...args});
              } else {
                Get.toNamed('/add-transaction', arguments: {'isEdit': true, ...args});
              }
            },
            backgroundColor: colorAccent,
            foregroundColor: colorOnAccent,
            icon: Icons.edit,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (context) => _confirmDelete(
              tx.id,
              tx.accountId,
              tx.destinationAccountId,
              tx.amount ?? 0,
              isExpense,
              isTransfer,
            ),
            backgroundColor: colorExpense,
            foregroundColor: colorWhite,
            icon: Icons.delete,
            label: 'Hapus',
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        onTap: () => Get.toNamed('/transaction-detail', arguments: args),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: iconBg,
          child: CategoryIcon(
            iconCode: iconCode,
            iconPath: iconPath,
            color: iconColor,
            size: 20,
          ),
        ),
        title: Text(
          tx.note?.isNotEmpty == true ? tx.note! : (tx.categoryName ?? '-'),
          style: const TextStyle(
            color: colorWhite,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              if (showDate && tx.date != null) ...[
                Text(
                  '${tx.date!.day.toString().padLeft(2, '0')}/${tx.date!.month.toString().padLeft(2, '0')}/${tx.date!.year} • ',
                  style: const TextStyle(color: colorGrey, fontSize: 12),
                ),
              ],
              Text(
                tx.accountName ?? 'CASH',
                style: const TextStyle(color: colorGrey, fontSize: 12),
              ),
              if (isTransfer && tx.destinationAccountName != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_forward, color: colorGrey, size: 12),
                ),
                Text(
                  tx.destinationAccountName!,
                  style: const TextStyle(color: colorGrey, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        trailing: Text(
          '$prefix${CurrencyService.to.format(displayAmount)}',
          style: TextStyle(
            color: amountColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    int? id,
    int? accountId,
    int? destinationAccountId,
    int amount,
    bool isExpense,
    bool isTransfer,
  ) {
    if (id == null) return;
    bool isDeleting = false;
    Get.defaultDialog(
      backgroundColor: colorCard,
      title: 'Hapus Transaksi',
      titleStyle: const TextStyle(
          color: colorWhite, fontWeight: FontWeight.bold, fontSize: 16),
      middleText:
          'Transaksi ini akan dihapus secara permanen dan saldo rekening akan disesuaikan kembali.',
      middleTextStyle: const TextStyle(color: colorGrey, fontSize: 13),
      radius: 12,
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: colorExpense),
        onPressed: () async {
          if (isDeleting) return;
          isDeleting = true;
          try {
            await DatabaseHelper.instance.deleteTransactionWithBalanceUpdate(
                id, accountId, destinationAccountId, amount, isExpense, isTransfer);
            refreshAllGlobalData();
            Get.back(); // close dialog
            Get.snackbar(
              'Berhasil',
              'Transaksi telah dihapus',
              backgroundColor: Colors.green.shade800,
              colorText: colorWhite,
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(16),
            );
          } finally {
            isDeleting = false;
          }
        },
        child: const Text('Hapus', style: TextStyle(color: colorWhite)),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Batal', style: TextStyle(color: colorGrey)),
      ),
    );
  }
}
