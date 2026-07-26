import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:artavia/core/database/database_helper.dart';

class BudgetController extends GetxController {
  final isLoading = false.obs;
  final currentDate = DateTime.now().obs;

  // Budget items: {id, category, budget_amount, used, color, icon}
  final budgetItems = <Map<String, dynamic>>[].obs;

  int get totalBudget =>
      budgetItems.fold(0, (s, i) => s + (i['budget_amount'] as int));
  int get totalUsed =>
      budgetItems.fold(0, (s, i) => s + (i['used'] as int));

  // Available categories from DB
  final availableCategories = <Map<String, dynamic>>[].obs;
  
  final RxBool isWorking = false.obs;

  String get monthLabel {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${months[currentDate.value.month]} ${currentDate.value.year}';
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void prevMonth() {
    final d = currentDate.value;
    currentDate.value = DateTime(d.year, d.month - 1);
    loadData();
  }

  void nextMonth() {
    final d = currentDate.value;
    currentDate.value = DateTime(d.year, d.month + 1);
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      final year = currentDate.value.year;
      final month = currentDate.value.month;

      // Load budgets for current month
      final budgets =
          await DatabaseHelper.instance.readBudgetsByMonth(year, month);

      // Load transactions for current month to compute 'used'
      final transactions =
          await DatabaseHelper.instance.readTransactionsByMonth(year, month);

      // Load categories for color/icon info
      final cats = await DatabaseHelper.instance.readAllCategories();

      final Map<String, Map<String, dynamic>> catMap = {};
      for (var c in cats) {
        catMap[c['name'] as String] = c;
      }
      availableCategories.value = cats
          .where((c) => c['type'] == 'pengeluaran')
          .map((c) => {'name': c['name'], 'id': c['id']})
          .toList();

      // Sum used per category
      final Map<String, int> usedByCat = {};
      for (var t in transactions) {
        if (t['type'] == 'pengeluaran') {
          final cat = (t['categoryName'] as String?) ?? 'Lainnya';
          usedByCat[cat] = (usedByCat[cat] ?? 0) + (t['amount'] as int);
        }
      }

      final catColors = [
        0xFF4CAF50, 0xFF9C27B0, 0xFFFF9800, 0xFFF44336,
        0xFF2196F3, 0xFFE91E63, 0xFF00BCD4, 0xFFFFEB3B,
      ];
      final catIcons = [
        Icons.restaurant, Icons.directions_car, Icons.shopping_bag,
        Icons.medical_services, Icons.home, Icons.movie,
        Icons.fitness_center, Icons.category,
      ];

      final List<Map<String, dynamic>> items = [];
      int idx = 0;
      for (var b in budgets) {
        final catName = (b['categoryName'] as String?) ?? '';
        final catData = catMap[catName];

        items.add({
          'id': b['id'],
          'category_id': b['category_id'] as int?,
          'category': catName,
          'budget_amount': b['budget_amount'] as int,
          'used': usedByCat[catName] ?? 0,
          'color': catData != null && catData['color_val'] != null
              ? catData['color_val'] as int
              : catColors[idx % catColors.length],
          'icon': catIcons[idx % catIcons.length],
        });
        idx++;
      }
      budgetItems.value = items;
    } finally {
      isLoading.value = false;
    }
  }

  void showAddBudgetDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String? selectedCategory;
    final amountCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Tambah Anggaran',
            style: TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() => DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF1E1E1E),
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey)),
                    ),
                    style: const TextStyle(color: Colors.white),
                    items: availableCategories
                        .map((c) => DropdownMenuItem<String>(
                              value: c['name'] as String,
                              child: Text(c['name'] as String),
                            ))
                        .toList(),
                    validator: (v) =>
                        v == null ? 'Pilih kategori' : null,
                    onChanged: (v) => selectedCategory = v,
                  )),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Anggaran (Rp)',
                  labelStyle: TextStyle(color: Colors.grey),
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(12),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (v) =>
                    (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Masukkan nominal' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCA28)),
            onPressed: () async {
              if (isWorking.value) return;
              if (formKey.currentState!.validate() &&
                  selectedCategory != null) {
                isWorking.value = true;
                try {
                  final amount = int.tryParse(amountCtrl.text) ?? 0;
                  final catId = availableCategories.firstWhere((c) => c['name'] == selectedCategory)['id'] as int;
                  await DatabaseHelper.instance.upsertBudget(
                    categoryId: catId,
                    amount: amount,
                    month: currentDate.value.month,
                    year: currentDate.value.year,
                  );
                  Get.back();
                  loadData();
                  Get.snackbar('Berhasil', 'Anggaran disimpan',
                      snackPosition: SnackPosition.BOTTOM);
                } finally {
                  isWorking.value = false;
                }
              }
            },
            child: const Text('Simpan',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void showEditBudgetDialog(BuildContext context, Map<String, dynamic> item) {
    final amountCtrl = TextEditingController(
        text: (item['budget_amount'] as int).toString());

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('Edit Anggaran – ${item['category']}',
            style: const TextStyle(color: Colors.white)),
        content: TextFormField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Anggaran (Rp)',
            labelStyle: TextStyle(color: Colors.grey),
            prefixText: 'Rp ',
            prefixStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey)),
          ),
          inputFormatters: [
            LengthLimitingTextInputFormatter(12),
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCA28)),
            onPressed: () async {
              if (isWorking.value) return;
              final amount = int.tryParse(amountCtrl.text) ?? 0;
              if (amount > 0) {
                isWorking.value = true;
                try {
                  await DatabaseHelper.instance.upsertBudget(
                    categoryId: item['category_id'] as int,
                    amount: amount,
                    month: currentDate.value.month,
                    year: currentDate.value.year,
                  );
                  Get.back();
                  loadData();
                } finally {
                  isWorking.value = false;
                }
              }
            },
            child: const Text('Simpan',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> deleteBudget(int id) async {
    if (isWorking.value) return;
    isWorking.value = true;
    try {
      await DatabaseHelper.instance.deleteBudget(id);
      loadData();
    } finally {
      isWorking.value = false;
    }
  }
}
