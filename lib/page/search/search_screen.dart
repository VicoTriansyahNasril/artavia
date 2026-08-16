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
                        color: isSelected ? colorOnAccent : colorWhite,
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
                return Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Material(
                    color: colorCard,
                    child: _buildTransactionItem(list[index]),
                  ),
                );
              },
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
