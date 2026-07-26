import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';

class CategoryManagementController extends GetxController {
  final currentTab = 'Pengeluaran'.obs;

  final expenseCategories = <Map<String, dynamic>>[].obs;
  final incomeCategories = <Map<String, dynamic>>[].obs;

  final isExpenseForm = true.obs;
  final categoryName = ''.obs;
  final selectedIcon = Icons.category.obs;
  final selectedColor = (Colors.grey as Color).obs;

  // Edit mode
  final editingId = Rx<int?>(null);
  bool get isEditMode => editingId.value != null;

  final presetIcons = <IconData>[
    Icons.restaurant, Icons.local_drink, Icons.shopping_cart, Icons.directions_bus,
    Icons.home, Icons.electrical_services, Icons.phone_android, Icons.movie,
    Icons.medical_services, Icons.school, Icons.pets, Icons.flight,
    Icons.fitness_center, Icons.local_gas_station, Icons.child_care, Icons.category,
    Icons.sports_esports, Icons.coffee, Icons.local_taxi, Icons.beach_access,
    Icons.attach_money, Icons.trending_up, Icons.savings, Icons.card_giftcard,
  ];

  final presetColors = <Color>[
    Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
    Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
    Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
    Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
    Colors.brown, Colors.grey, Colors.blueGrey, Colors.black,
  ];

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  void resetForm() {
    editingId.value = null;
    categoryName.value = '';
    selectedIcon.value = Icons.category;
    selectedColor.value = Colors.grey;
  }

  Future<void> loadCategories() async {
    final cats = await DatabaseHelper.instance.readAllCategories();
    final exList = <Map<String, dynamic>>[];
    final inList = <Map<String, dynamic>>[];

    for (var c in cats) {
      final type = c['type'];
      final codePoint = c['icon_code'];
      final colorVal = c['color_val'];

      IconData iconData = Icons.category;
      if (codePoint != null) {
        // ignore: non_const_argument_for_const_parameter
        iconData = IconData(codePoint as int, fontFamily: 'MaterialIcons');
      }

      Color colorData = Colors.grey;
      if (colorVal != null) {
        colorData = Color(colorVal as int);
      }

      final item = {
        'id': c['id'],
        'name': c['name'],
        'icon': iconData,
        'color': colorData,
      };

      if (type == 'pengeluaran') {
        exList.add(item);
      } else {
        inList.add(item);
      }
    }
    expenseCategories.value = exList;
    incomeCategories.value = inList;
  }

  void changeTab(String tab) {
    currentTab.value = tab;
  }

  Future<void> saveCategory() async {
    if (categoryName.value.trim().isEmpty) {
      Get.snackbar('Gagal', 'Nama kategori tidak boleh kosong',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // ignore: deprecated_member_use
    final cVal = selectedColor.value.value;
    final data = {
      'name': categoryName.value.trim(),
      'type': isExpenseForm.value ? 'pengeluaran' : 'pemasukan',
      'icon_code': selectedIcon.value.codePoint,
      'color_val': cVal,
    };

    if (isEditMode) {
      await DatabaseHelper.instance.updateCategory(editingId.value!, data);
      Get.back();
      Get.snackbar('Berhasil', 'Kategori berhasil diperbarui',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      await DatabaseHelper.instance.insertCategory(data);
      Get.back();
      Get.snackbar('Berhasil', 'Kategori baru disimpan',
          snackPosition: SnackPosition.BOTTOM);
    }

    resetForm();
    loadCategories();
  }

  void deleteCategory(int id) async {
    Get.defaultDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: 'Hapus Kategori',
      titleStyle: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold),
      middleText:
          'Kategori ini akan dihapus. Transaksi yang sudah ada tidak akan terpengaruh.',
      middleTextStyle:
          const TextStyle(color: Colors.grey, fontSize: 13),
      radius: 8,
      confirm: ElevatedButton(
        style:
            ElevatedButton.styleFrom(backgroundColor: Colors.red),
        onPressed: () async {
          try {
            await DatabaseHelper.instance.deleteCategory(id);
            Get.back();
            loadCategories();
            Get.snackbar('Berhasil', 'Kategori dihapus',
                snackPosition: SnackPosition.BOTTOM);
          } catch (e) {
            Get.back();
            Get.snackbar('Gagal', 'Tidak dapat menghapus kategori yang sudah digunakan pada transaksi.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red.shade800,
                colorText: Colors.white,
                margin: const EdgeInsets.all(16));
          }
        },
        child:
            const Text('Hapus', style: TextStyle(color: Colors.white)),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Batal',
            style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
