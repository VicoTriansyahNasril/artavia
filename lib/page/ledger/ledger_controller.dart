import 'package:get/get.dart';

class LedgerController extends GetxController {
  final ledgers = [
    {'id': '1', 'name': 'Buku Kas Pribadi', 'isDefault': true},
    {'id': '2', 'name': 'Buku Kas Bisnis', 'isDefault': false},
    {'id': '3', 'name': 'Liburan Bali', 'isDefault': false},
  ].obs;

  final selectedLedgerId = '1'.obs;

  void selectLedger(String id) {
    selectedLedgerId.value = id;
    Get.back();
    Get.snackbar('Berhasil', 'Beralih ke buku kas baru', snackPosition: SnackPosition.BOTTOM);
  }
}
