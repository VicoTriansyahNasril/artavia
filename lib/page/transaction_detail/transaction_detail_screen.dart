import 'package:flutter/material.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/utils/data_refresh.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key});

  static Color _resolveColor(String? cat, bool isExpense, bool isTransfer) {
    if (isTransfer) return Colors.blue;
    return isExpense ? colorExpense : colorIncome;
  }

  @override
  Widget build(BuildContext context) {
    final arg = Get.arguments;
    final String? id = arg?['id']?.toString();
    final String type = arg?['type'] ?? 'pengeluaran';
    final int amount = arg?['amount'] ?? 0;
    final String category = arg?['category'] ?? 'Lainnya';
    final String note = arg?['note'] ?? '';
    final String account = arg?['account'] ?? 'CASH';
    final int? accountId = arg?['account_id'];
    final String destinationAccount = arg?['destination_account'] ?? '';
    final int? destinationAccountId = arg?['destination_account_id'];
    final DateTime date = arg?['date'] ?? DateTime.now();

    final isExpense = type == 'pengeluaran';
    final isTransfer = type == 'transfer';

    final iconCode = arg?['icon_code'] as int?;
    final iconPath = arg?['icon_path'] as String?;
    final colorVal = arg?['color_val'] as int?;

    final themeColor = colorVal != null
        ? Color(colorVal)
        : _resolveColor(category, isExpense, isTransfer);

    return Scaffold(
      backgroundColor: colorBackground,
      body: Column(
        children: [
          // ─── Gradient hero header ───────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeColor.withValues(alpha: 0.85), themeColor.withValues(alpha: 0.3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Close / edit / delete actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: colorWhite),
                          onPressed: () => Get.back(),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: colorWhite),
                          onPressed: () {
                            Get.toNamed('/add-transaction', arguments: {
                              'isEdit': true,
                              'id': id,
                              'type': type,
                              'amount': amount,
                              'category': category,
                              'note': note,
                              'account': account,
                              'account_id': accountId,
                              'date': date,
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: colorWhite),
                          onPressed: () => _confirmDelete(id, accountId, destinationAccountId, amount, isExpense, isTransfer),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: CategoryIcon(
                      iconCode: iconCode ?? (isExpense ? Icons.arrow_upward.codePoint : Icons.arrow_downward.codePoint),
                      iconPath: iconPath,
                      color: colorWhite,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    category,
                    style: const TextStyle(
                        color: colorWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${isExpense ? '-' : isTransfer ? '' : '+'}${CurrencyService.to.format(amount)}',
                    style: const TextStyle(
                        color: colorWhite,
                        fontSize: 36,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ─── Detail rows ─────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    color: colorCard,
                    child: Column(
                      children: [
                        _buildRow(
                          Icons.swap_vert_circle_rounded,
                          'Jenis',
                          isTransfer
                              ? 'Transfer'
                              : isExpense
                                  ? 'Pengeluaran'
                                  : 'Pemasukan',
                          valueColor: themeColor,
                        ),
                        _divider(),
                        _buildRow(Icons.grid_view_rounded, 'Kategori', category),
                        _divider(),
                        _buildRow(Icons.account_balance_wallet_rounded,
                            'Rekening', isTransfer ? '$account -> $destinationAccount' : account),
                        _divider(),
                        _buildRow(
                          Icons.calendar_today_rounded,
                          'Tanggal',
                          DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date),
                        ),
                        _divider(),
                        _buildRow(
                          Icons.access_time_rounded,
                          'Waktu',
                          DateFormat('HH:mm', 'id_ID').format(date),
                        ),
                        if (note.isNotEmpty) ...[
                          _divider(),
                          _buildRow(Icons.notes_rounded, 'Catatan', note),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Delete button at bottom
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _confirmDelete(id, accountId, destinationAccountId, amount, isExpense, isTransfer),
                        icon: const Icon(Icons.delete_outline,
                            color: colorExpense),
                        label: const Text('Hapus Transaksi',
                            style: TextStyle(color: colorExpense)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: colorExpense),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value,
      {Color valueColor = colorWhite}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            child: Text(
              value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        color: colorGrey.withValues(alpha: 0.08),
        height: 1,
        indent: 16,
      );

  void _confirmDelete(
      String? id, int? accountId, int? destinationAccountId, int amount, bool isExpense, bool isTransfer) {
    bool isDeleting = false;
    Get.defaultDialog(
      backgroundColor: colorCard,
      title: 'Hapus Transaksi',
      titleStyle: const TextStyle(
          color: colorWhite, fontWeight: FontWeight.bold, fontSize: 16),
      middleText:
          'Transaksi akan dihapus permanen dan saldo rekening akan disesuaikan.',
      middleTextStyle: const TextStyle(color: colorGrey, fontSize: 13),
      radius: 12,
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: colorExpense),
        onPressed: () async {
          if (isDeleting) return;
          isDeleting = true;
          try {
            if (id != null) {
              await DatabaseHelper.instance.deleteTransactionWithBalanceUpdate(
                  int.parse(id), accountId, destinationAccountId, amount, isExpense, isTransfer);
              refreshAllGlobalData();
            }
            Get.back(); // close dialog
            Get.back(); // go back
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
