import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/page/category_management/category_management_controller.dart';
import 'package:artavia/widgets/commons/common.dart';

class CategoryManagementScreen
    extends GetView<CategoryManagementController> {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        backgroundColor: colorBackground,
        elevation: 0,
        title: const Text(
          'Pengaturan Kategori',
          style: TextStyle(
            color: colorWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: colorWhite),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(child: _buildCategoryList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.isExpenseForm.value =
              controller.currentTab.value == 'Pengeluaran';
          controller.resetForm();
          Get.toNamed('/add-category');
        },
        backgroundColor: colorAccent,
        icon: const Icon(Icons.add, color: colorBlack),
        label: const Text(
          'Tambah Kategori',
          style: TextStyle(
            color: colorBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Obx(() {
      final isExpense = controller.currentTab.value == 'Pengeluaran';
      return Container(
        color: colorBackground,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: colorCard,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildTab('Pengeluaran', isExpense),
              _buildTab('Pemasukan', !isExpense),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTab(String title, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeTab(title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colorAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? colorBlack : colorGrey,
              fontSize: 14,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return Obx(() {
      final isExpense = controller.currentTab.value == 'Pengeluaran';
      final list = isExpense
          ? controller.expenseCategories
          : controller.incomeCategories;

      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.category_outlined,
                size: 56,
                color: colorGrey.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada kategori',
                style: TextStyle(
                  color: colorWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ketuk + untuk menambah kategori baru',
                style: TextStyle(color: colorGrey, fontSize: 13),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final cat = list[index];
          final color = cat['color'] as Color;
          final icon = cat['icon'] as IconData;
          final id = cat['id'] as int;

          return Column(
            children: [
              if (index > 0)
                const Divider(
                  color: colorBackground,
                  height: 1,
                  indent: 64,
                ),
              Material(
                color: colorCard,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: color.withValues(alpha: 0.18),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  title: Text(
                    cat['name'] as String,
                    style: const TextStyle(
                      color: colorWhite,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: colorGrey,
                          size: 20,
                        ),
                        onPressed: () {
                          controller.isExpenseForm.value = isExpense;
                          controller.editingId.value = id;
                          controller.categoryName.value =
                              cat['name'] as String;
                          controller.selectedIcon.value =
                              cat['icon'] as IconData;
                          controller.selectedColor.value =
                              cat['color'] as Color;
                          Get.toNamed('/add-category');
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: colorExpense,
                          size: 20,
                        ),
                        onPressed: () => controller.deleteCategory(id),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }
}
