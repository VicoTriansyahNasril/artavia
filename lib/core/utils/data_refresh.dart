import 'package:get/get.dart';
import 'package:artavia/page/home/home_controller.dart';
import 'package:artavia/page/report/report_controller.dart';
import 'package:artavia/page/account_management/account_management_controller.dart';
import 'package:artavia/page/calendar/calendar_controller.dart';
import 'package:artavia/page/budget/budget_controller.dart';
import 'package:artavia/page/settings/settings_controller.dart';
import 'package:artavia/page/search/search_controller.dart' as app_search;

/// Memperbarui semua data pada seluruh controller yang sedang aktif di memory.
/// Dipanggil setelah ada perubahan data (tambah/edit/hapus Transaksi, Rekening,
/// Kategori, reset, restore, atau impor).
void refreshAllGlobalData() {
  if (Get.isRegistered<HomeController>()) {
    Get.find<HomeController>().loadData();
  }
  if (Get.isRegistered<ReportController>()) {
    Get.find<ReportController>().loadData();
  }
  if (Get.isRegistered<AccountManagementController>()) {
    Get.find<AccountManagementController>().loadAccounts();
  }
  if (Get.isRegistered<CalendarController>()) {
    final c = Get.find<CalendarController>();
    c.loadMonth(c.focusedDay.value);
    c.loadDayTransactions(c.selectedDay.value);
  }
  if (Get.isRegistered<BudgetController>()) {
    Get.find<BudgetController>().loadData();
  }
  if (Get.isRegistered<SettingsController>()) {
    Get.find<SettingsController>().loadStats();
  }
  if (Get.isRegistered<app_search.SearchController>()) {
    Get.find<app_search.SearchController>().doSearch();
  }
}
