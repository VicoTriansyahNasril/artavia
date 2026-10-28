import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/utils/data_refresh.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/components/app_feedback.dart';

class CategoryManagementController extends GetxController {
  final currentTab = 'Pengeluaran'.obs;

  final expenseCategories = <Map<String, dynamic>>[].obs;
  final incomeCategories = <Map<String, dynamic>>[].obs;

  final isExpenseForm = true.obs;

  final RxBool isWorking = false.obs;

  final categoryName = ''.obs;
  final selectedIconPath = Rx<String?>(null);
  final selectedIconCode = Rx<int?>(null);
  final selectedColor = categoryPalette.first.obs;

  // Edit mode
  final editingId = Rx<int?>(null);
  bool get isEditMode => editingId.value != null;

  final categorizedIcons = {
    'Keuangan': AppIcons.keuangan,
    'Makanan': AppIcons.makanan,
    'Belanja': AppIcons.belanja,
    'Transportasi': AppIcons.transportasi,
    'Hiburan': AppIcons.hiburan,
    'Kesehatan': AppIcons.kesehatan,
    'Pendidikan': AppIcons.pendidikan,
    'Olahraga': AppIcons.olahraga,
    'Berpergian': AppIcons.berpergian,
    'Kehidupan': AppIcons.kehidupan,
    'Pribadi': AppIcons.pribadi,
  };

  final presetColors = categoryPalette;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  void resetForm() {
    editingId.value = null;
    categoryName.value = '';
    selectedIconPath.value = null;
    selectedIconCode.value = null;
    selectedColor.value = categoryPalette.first;
  }

  Future<void> loadCategories() async {
    final cats = await DatabaseHelper.instance.readAllCategories();
    final exList = <Map<String, dynamic>>[];
    final inList = <Map<String, dynamic>>[];

    for (var c in cats) {
      final type = c['type'];
      final codePoint = c['icon_code'];
      final iconPath = c['icon_path'];
      final colorVal = c['color_val'];

      final colorData = colorVal != null ? Color(colorVal as int) : colorGrey;

      final item = {
        'id': c['id'],
        'name': c['name'],
        'icon_code': codePoint,
        'icon_path': iconPath,
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
    if (isWorking.value) return;
    if (categoryName.value.trim().isEmpty) {
      AppToast.warning('Gagal', 'Nama kategori tidak boleh kosong');
      return;
    }

    isWorking.value = true;
    try {
      final cVal = selectedColor.value.toARGB32();
      final data = {
        'name': categoryName.value.trim(),
        'type': isExpenseForm.value ? 'pengeluaran' : 'pemasukan',
        'icon_code': selectedIconCode.value,
        'icon_path': selectedIconPath.value,
        'color_val': cVal,
      };

      if (isEditMode) {
        await DatabaseHelper.instance.updateCategory(editingId.value!, data);
        Get.back();
        AppToast.success('Berhasil', 'Kategori berhasil diperbarui');
      } else {
        await DatabaseHelper.instance.insertCategory(data);
        Get.back();
        AppToast.success('Berhasil', 'Kategori baru disimpan');
      }

      resetForm();
      loadCategories();
      refreshAllGlobalData();
    } finally {
      isWorking.value = false;
    }
  }

  Future<void> deleteCategory(int id) async {
    final ok = await AppDialog.confirm(
      title: 'Hapus Kategori',
      message:
          'Kategori yang sudah dipakai pada transaksi tidak dapat dihapus. '
          'Anggaran dan transaksi berulang untuk kategori ini ikut terhapus.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!ok || isWorking.value) return;
    isWorking.value = true;
    try {
      await DatabaseHelper.instance.deleteCategory(id);
      loadCategories();
      refreshAllGlobalData();
      AppToast.success('Berhasil', 'Kategori dihapus');
    } catch (e) {
      AppToast.error('Tidak Dapat Dihapus',
          'Kategori ini sudah digunakan pada transaksi.');
    } finally {
      isWorking.value = false;
    }
  }
}
