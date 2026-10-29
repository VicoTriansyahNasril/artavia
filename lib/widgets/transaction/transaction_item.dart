import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/database/transaction_store.dart';
import 'package:artavia/model/transaction_model.dart';
import 'package:artavia/page/routes.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';
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
    'category_id': tx.categoryId,
    'note': tx.note,
    'account': tx.accountName ?? '—',
    'account_id': tx.accountId,
    'destination_account': tx.destinationAccountName,
    'destination_account_id': tx.destinationAccountId,
    'admin_fee': tx.adminFee ?? 0,
    'admin_fee_type': tx.adminFeeType,
    'date': tx.date,
    'icon_code': visual.iconCode,
    'icon_path': visual.iconPath,
    'icon_key': tx.type == 'transfer' ? 'transfer' : tx.categoryIconKey,
    'color_val': visual.color.toARGB32(),
  };
}

/// Opens Catat in edit mode; the type picks the segment.
void openTransactionEditor(Map<String, dynamic> args) {
  Get.toNamed(addTransactionRoute, arguments: {'isEdit': true, ...args});
}

/// Deletes right away and offers "Urungkan" for 5 seconds (FR-015); undo
/// puts the row back under the same id with its balance effect.
Future<bool> deleteTransactionWithUndo(int? id, {String? label}) async {
  if (id == null) return false;
  final db = DatabaseHelper.instance;
  try {
    final snapshot = await db.deleteTransactionById(id);
    if (snapshot == null) return false;
    refreshAllGlobalData();
    final name = (label ?? '').trim();
    AppToast.undo(
      name.isEmpty ? 'Transaksi dihapus' : '“$name” dihapus',
      onUndo: () async {
        await db.restoreTransaction(snapshot);
        refreshAllGlobalData();
      },
    );
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
      return TransactionVisual(themedColor(tx.categoryColorVal),
          hasIcon ? tx.categoryIconCode : fallbackIcon, tx.categoryIconPath);
    }
    return TransactionVisual(
        isExpense ? colorExpense : colorIncome, fallbackIcon, null);
  }
}

class TransactionItem extends StatelessWidget {
  final TransactionModel tx;
  final bool showDate;
  final String? highlight;
  const TransactionItem(
      {super.key, required this.tx, this.showDate = false, this.highlight});

  @override
  Widget build(BuildContext context) {
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
            icon: LucideIcons.pencil,
            label: 'Ubah',
          ),
          SlidableAction(
            onPressed: (_) => deleteTransactionWithUndo(tx.id,
                label: tx.note?.isNotEmpty == true ? tx.note : tx.categoryName),
            backgroundColor: colorSurface,
            foregroundColor: colorDanger,
            icon: LucideIcons.trash2,
            label: 'Hapus',
          ),
        ],
      ),
      child: TxRow(
        tx: tx,
        showDate: showDate,
        highlight: highlight,
        onTap: () => Get.toNamed(transactionDetailRoute, arguments: args),
      ),
    );
  }
}
