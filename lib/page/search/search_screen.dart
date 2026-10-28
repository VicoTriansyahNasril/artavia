import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/transaction/transaction_item.dart';
import 'package:artavia/model/transaction_model.dart';
import 'package:artavia/page/search/search_controller.dart' as app_search;

class SearchScreen extends GetView<app_search.SearchController> {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          style: const TextStyle(color: colorText, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Cari catatan atau kategori…',
            border: InputBorder.none,
            filled: false,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: double.infinity,
      child: Obx(() => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  ['Semua', 'Pengeluaran', 'Pemasukan', 'Transfer'].map((type) {
                final isSelected = controller.filterType.value == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (_) => controller.filterType.value = type,
                    labelStyle: TextStyle(
                        color: isSelected ? colorAccent : colorGrey,
                        fontSize: 13),
                    showCheckmark: false,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

      if (controller.searchQuery.value.isEmpty &&
          controller.filterType.value == 'Semua') {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search,
                  size: 64, color: colorGrey.withValues(alpha: 0.3)),
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
                  size: 64, color: colorGrey.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                controller.searchQuery.value.isEmpty
                    ? 'Tidak ada transaksi ${controller.filterType.value.toLowerCase()}'
                    : 'Tidak ada hasil untuk\n"${controller.searchQuery.value}"',
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Obx(() => Text(
                      '${list.length} transaksi ditemukan',
                      style: const TextStyle(color: colorGrey, fontSize: 12),
                    )),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(indent: 68),
              itemBuilder: (context, index) => Material(
                color: colorCard,
                child: _buildTransactionItem(list[index]),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTransactionItem(TransactionModel tx) {
    return TransactionItem(tx: tx, showDate: true);
  }
}
