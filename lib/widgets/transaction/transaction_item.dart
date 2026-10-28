import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/database/transaction_store.dart';
import 'package:artavia/core/utils/date_format.dart';
import 'package:artavia/model/transaction_model.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/components/app_feedback.dart';
import 'package:artavia/core/utils/data_refresh.dart';

/// Arguments shared by the detail, edit and transfer screens for [tx].
Map<String, dynamic> transactionArgs(TransactionModel tx) {
  final visual = TransactionVisual.of(tx);
  return {
    'id': tx.id,
    'type': tx.type,
    'amount': (tx.amount ?? 0).abs(),
    'category': tx.categoryName,
    'note': tx.note,
    'account': tx.accountName ?? '-',
    'account_id': tx.accountId,
    'destination_account': tx.destinationAccountName,
    'destination_account_id': tx.destinationAccountId,
    'admin_fee': tx.adminFee ?? 0,
    'admin_fee_type': tx.adminFeeType,
    'date': tx.date,
    'icon_code': visual.iconCode,
    'icon_path': visual.iconPath,
    'color_val': visual.color.toARGB32(),
  };
}

/// Opens the right edit form for the transaction type (FR-011).
void openTransactionEditor(Map<String, dynamic> args) {
  final route =
      args['type'] == 'transfer' ? transferRoute : addTransactionRoute;
  Get.toNamed(route, arguments: {'isEdit': true, ...args});
}

/// Confirms, deletes (balances restored from the stored row) and refreshes.
Future<bool> confirmDeleteTransaction(int? id) async {
  if (id == null) return false;
  final ok = await AppDialog.confirm(
    title: 'Hapus Transaksi',
    message:
        'Transaksi ini akan dihapus permanen dan saldo rekening disesuaikan kembali.',
    confirmLabel: 'Hapus',
    destructive: true,
  );
  if (!ok) return false;
  try {
    await DatabaseHelper.instance.deleteTransactionById(id);
    refreshAllGlobalData();
    AppToast.success('Berhasil', 'Transaksi telah dihapus');
    return true;
  } catch (e) {
    AppToast.error('Gagal', 'Transaksi tidak dapat dihapus');
    return false;
  }
}

/// Icon + color a transaction is drawn with.
class TransactionVisual {
  final Color color;
  final int? iconCode;
  final String? iconPath;

  const TransactionVisual(this.color, this.iconCode, this.iconPath);

  factory TransactionVisual.of(TransactionModel tx) {
    final isExpense = tx.type == 'pengeluaran';
    if (tx.type == 'transfer') {
      return TransactionVisual(colorAccent, Icons.swap_horiz.codePoint, null);
    }
    final fallbackIcon = isExpense
        ? Icons.arrow_upward.codePoint
        : Icons.arrow_downward.codePoint;
    if (tx.categoryColorVal != null && tx.categoryColorVal != 0) {
      final hasIcon =
          tx.categoryIconCode != null || tx.categoryIconPath != null;
      return TransactionVisual(Color(tx.categoryColorVal!),
          hasIcon ? tx.categoryIconCode : fallbackIcon, tx.categoryIconPath);
    }
    return TransactionVisual(
        isExpense ? colorExpense : colorIncome, fallbackIcon, null);
  }
}

class TransactionItem extends StatelessWidget {
  final TransactionModel tx;
  final bool showDate;
  const TransactionItem({super.key, required this.tx, this.showDate = false});

  @override
  Widget build(BuildContext context) {
    final isExpense = tx.type == 'pengeluaran';
    final isTransfer = tx.type == 'transfer';
    final visual = TransactionVisual.of(tx);
    final amountColor = isTransfer
        ? colorGrey
        : isExpense
            ? colorExpense
            : colorIncome;
    final prefix = isTransfer
        ? ''
        : isExpense
            ? '-'
            : '+';
    final args = transactionArgs(tx);

    return Slidable(
      key: ValueKey(tx.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.4,
        children: [
          SlidableAction(
            onPressed: (_) => openTransactionEditor(args),
            backgroundColor: colorSurface,
            foregroundColor: colorAccent,
            icon: Icons.edit_outlined,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (_) => confirmDeleteTransaction(tx.id),
            backgroundColor: colorSurface,
            foregroundColor: colorExpense,
            icon: Icons.delete_outline,
            label: 'Hapus',
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: () => Get.toNamed(transactionDetailRoute, arguments: args),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: visual.color.withValues(alpha: 0.14),
          child: CategoryIcon(
            iconCode: visual.iconCode,
            iconPath: visual.iconPath,
            color: visual.color,
            size: 18,
          ),
        ),
        title: Text(
          tx.note?.isNotEmpty == true
              ? tx.note!
              : (tx.categoryName ?? 'Transfer'),
          style: const TextStyle(
            color: colorText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            _subtitle(isTransfer),
            style: const TextStyle(color: colorGrey, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Text(
          '$prefix${CurrencyService.to.format((tx.amount ?? 0).abs())}',
          style: TextStyle(
            color: amountColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _subtitle(bool isTransfer) {
    final parts = <String>[
      if (showDate && tx.date != null) IdNames.shortDate(tx.date!),
      isTransfer && tx.destinationAccountName != null
          ? '${tx.accountName ?? '-'} → ${tx.destinationAccountName}'
          : tx.accountName ?? '-',
    ];
    return parts.join(' · ');
  }
}
