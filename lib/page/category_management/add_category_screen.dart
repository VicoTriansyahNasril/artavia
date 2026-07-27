import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/page/category_management/category_management_controller.dart';
import 'package:artavia/widgets/commons/common.dart';

class AddCategoryScreen extends GetView<CategoryManagementController> {
  const AddCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        backgroundColor: colorBackground,
        title: Obx(() => Text(
              controller.isEditMode ? 'Edit Kategori' : 'Tambah Kategori',
              style: const TextStyle(color: colorWhite, fontSize: 18),
            )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: colorWhite),
          onPressed: () {
            controller.resetForm();
            Get.back();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => controller.saveCategory(),
            child: const Text('Simpan',
                style: TextStyle(color: colorAccent, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeToggle(),
            const SizedBox(height: 16),
            _buildNameInput(),
            const SizedBox(height: 24),
            const Text('Pilih Warna',
                style: TextStyle(
                    color: colorGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const SizedBox(height: 16),
            _buildColorPicker(),
            const SizedBox(height: 24),
            const Text('Pilih Ikon',
                style: TextStyle(
                    color: colorGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const SizedBox(height: 16),
            _buildIconPicker(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Obx(() {
      final isExpense = controller.isExpenseForm.value;
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => controller.isExpenseForm.value = true,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isExpense
                      ? colorExpense.withValues(alpha: 0.85)
                      : colorCard,
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(8)),
                ),
                alignment: Alignment.center,
                child: Text('Pengeluaran',
                    style: TextStyle(
                        color: isExpense ? colorWhite : colorGrey,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => controller.isExpenseForm.value = false,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isExpense
                      ? colorIncome.withValues(alpha: 0.85)
                      : colorCard,
                  borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(8)),
                ),
                alignment: Alignment.center,
                child: Text('Pemasukan',
                    style: TextStyle(
                        color: !isExpense ? colorWhite : colorGrey,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildNameInput() {
    return Container(
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Obx(() => CircleAvatar(
                backgroundColor:
                    controller.selectedColor.value.withValues(alpha: 0.2),
                child: Icon(controller.selectedIcon.value,
                    color: controller.selectedColor.value),
              )),
          const SizedBox(width: 16),
          Expanded(
            child: Obx(() => TextField(
                  key: ValueKey(controller.categoryName.value +
                      controller.editingId.value.toString()),
                  controller: TextEditingController(
                      text: controller.categoryName.value)
                    ..selection = TextSelection.fromPosition(
                        TextPosition(
                            offset: controller.categoryName.value.length)),
                  style: const TextStyle(color: colorWhite),
                  decoration: const InputDecoration(
                    hintText: 'Nama Kategori',
                    hintStyle: TextStyle(color: colorGrey),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 16),
                  ),
                  onChanged: (val) =>
                      controller.categoryName.value = val,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker() {
    return Obx(() => Wrap(
          spacing: 14,
          runSpacing: 14,
          children: controller.presetColors.map((color) {
            final isSelected = controller.selectedColor.value == color;
            return GestureDetector(
              onTap: () => controller.selectedColor.value = color,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: colorWhite, width: 3)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: color.withValues(alpha: 0.6),
                              blurRadius: 8)
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check,
                        color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ));
  }

  Widget _buildIconPicker() {
    return Container(
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Obx(() => Wrap(
            spacing: 16,
            runSpacing: 16,
            children: controller.presetIcons.map((icon) {
              final isSelected = controller.selectedIcon.value == icon;
              return GestureDetector(
                onTap: () => controller.selectedIcon.value = icon,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? controller.selectedColor.value
                        : colorBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: colorGrey.withValues(alpha: 0.2)),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? colorWhite : colorGrey,
                    size: 24,
                  ),
                ),
              );
            }).toList(),
          )),
    );
  }
}
