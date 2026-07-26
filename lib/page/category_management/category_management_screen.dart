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
        title: const Text('Pengaturan Kategori',
            style: TextStyle(color: colorWhite, fontSize: 18)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.isExpenseForm.value =
              controller.currentTab.value == 'Pengeluaran';
          controller.resetForm();
          Get.toNamed('/add-category');
        },
        backgroundColor: colorAccent,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: colorBlack),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: colorBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTab('Pengeluaran'),
          const SizedBox(width: 32),
          _buildTab('Pemasukan'),
        ],
      ),
    );
  }

  Widget _buildTab(String title) {
    return Obx(() {
      final isSelected = controller.currentTab.value == title;
      return GestureDetector(
        onTap: () => controller.changeTab(title),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? colorWhite : colorGrey,
                fontSize: 16,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 3,
                width: 20,
                color: colorAccent,
              )
          ],
        ),
      );
    });
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
              Icon(Icons.category_outlined,
                  size: 48, color: colorGrey.withOpacity(0.4)),
              const SizedBox(height: 12),
              const Text('Belum ada kategori',
                  style: TextStyle(color: colorGrey)),
              const SizedBox(height: 8),
              const Text('Ketuk + untuk menambah kategori baru',
                  style: TextStyle(color: colorGrey, fontSize: 12)),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 80, top: 8),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final cat = list[index];
          final color = cat['color'] as Color;
          final icon = cat['icon'] as IconData;
          final id = cat['id'] as int;

          return Container(
            color: colorCard,
            margin: const EdgeInsets.only(bottom: 1),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color),
              ),
              title: Text(cat['name'] as String,
                  style: const TextStyle(
                      color: colorWhite, fontWeight: FontWeight.w500)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: colorGrey, size: 20),
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
                    icon: const Icon(Icons.delete_outline,
                        color: colorExpense, size: 20),
                    onPressed: () => controller.deleteCategory(id),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
