import 'package:flutter/material.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:artavia/page/search/search_controller.dart' as app_search;
import 'package:artavia/model/transaction_model.dart';
import 'package:artavia/widgets/commons/common.dart';

class SearchScreen extends GetView<app_search.SearchController> {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        backgroundColor: colorBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: colorWhite),
          onPressed: () => Get.back(),
        ),
        title: TextField(
          autofocus: true,
          style: const TextStyle(color: colorWhite, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Cari catatan, nominal, atau kategori...',
            hintStyle: TextStyle(color: colorGrey),
            border: InputBorder.none,
          ),
          onChanged: (val) => controller.searchQuery.value = val,
        ),
        actions: [
          Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: colorGrey),
                  onPressed: () => controller.searchQuery.value = '',
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildResultList()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: colorCard,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: double.infinity,
      child: Obx(() => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Semua', 'Pengeluaran', 'Pemasukan', 'Transfer']
                  .map((type) {
                final isSelected = controller.filterType.value == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (_) => controller.filterType.value = type,
                    backgroundColor: colorBackground,
                    selectedColor: colorAccent,
                    labelStyle: TextStyle(
                        color: isSelected ? colorBlack : colorWhite,
                        fontSize: 13),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                  ),
                );
              }).toList(),
            ),
          )),
    );
  }

  Widget _buildResultList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final list = controller.filteredTransactions;

      if (controller.searchQuery.value.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search,
                  size: 64, color: colorGrey.withOpacity(0.3)),
              const SizedBox(height: 16),
              const Text('Ketik untuk mencari transaksi',
                  style: TextStyle(color: colorGrey)),
            ],
          ),
        );
      }

      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off,
                  size: 64, color: colorGrey.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text(
                'Tidak ada hasil untuk\n"${controller.searchQuery.value}"',
                textAlign: TextAlign.center,
                style: const TextStyle(color: colorGrey),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Obx(() => Text(
                      '${list.length} transaksi ditemukan',
                      style:
                          const TextStyle(color: colorGrey, fontSize: 12),
                    )),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final tx = list[index];
                return Container(
                  color: colorCard,
                  margin: const EdgeInsets.only(bottom: 1),
                  child: _buildTransactionItem(tx),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTransactionItem(TransactionModel tx) {
    final cat = tx.categoryName?.toLowerCase() ?? '';
    final isExpense = tx.type == 'pengeluaran';
    final isTransfer = tx.type == 'transfer';

    IconData iconData = Icons.category;
    Color bgColor = colorGrey;

    if (cat.contains('makan')) {
      iconData = Icons.restaurant;
      bgColor = Colors.orange;
    } else if (cat.contains('minum')) {
      iconData = Icons.local_cafe;
      bgColor = Colors.blue;
    } else if (cat.contains('belanja')) {
      iconData = Icons.shopping_cart;
      bgColor = Colors.purple;
    } else if (cat.contains('transport')) {
      iconData = Icons.directions_bus;
      bgColor = Colors.teal;
    } else if (cat.contains('gaji') || cat.contains('bonus')) {
      iconData = Icons.attach_money;
      bgColor = Colors.green;
    } else if (cat.contains('invest')) {
      iconData = Icons.trending_up;
      bgColor = Colors.cyan;
    } else if (cat.contains('kesehatan')) {
      iconData = Icons.medical_services;
      bgColor = Colors.red;
    } else if (cat.contains('hiburan')) {
      iconData = Icons.sports_esports;
      bgColor = Colors.pink;
    } else if (isTransfer) {
      iconData = Icons.swap_horiz;
      bgColor = Colors.blue;
    } else if (!isExpense) {
      iconData = Icons.arrow_downward;
      bgColor = colorIncome;
    } else {
      iconData = Icons.arrow_upward;
      bgColor = colorExpense;
    }

    final displayAmount = (tx.amount ?? 0).abs();
    final amountColor = isTransfer
        ? Colors.blue
        : isExpense
            ? colorExpense
            : colorIncome;

    return ListTile(
      onTap: () {
        Get.toNamed('/transaction-detail', arguments: {
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
        });
      },
      leading: CircleAvatar(
        backgroundColor: bgColor.withOpacity(0.2),
        child: Icon(iconData, color: bgColor, size: 20),
      ),
      title: Text(
        tx.note?.isNotEmpty == true
            ? tx.note!
            : (tx.categoryName ?? ''),
        style:
            const TextStyle(color: colorWhite, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${tx.categoryName ?? ''} • ${DateFormat('dd MMM yyyy', 'id_ID').format(tx.date!)} • ${tx.type == 'transfer' ? '${tx.accountName ?? ''} -> ${tx.destinationAccountName ?? ''}' : tx.accountName ?? ''}',
        style: const TextStyle(color: colorGrey, fontSize: 11),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${isExpense ? '-' : isTransfer ? '' : '+'}${CurrencyService.to.formatWithoutSymbol(displayAmount)}',
        style: TextStyle(
          color: amountColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
