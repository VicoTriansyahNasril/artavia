import 'package:get/get.dart';
import 'package:artavia/page/home/home_controller.dart';
import 'package:artavia/page/report/report_controller.dart';
import 'package:artavia/page/chart/chart_controller.dart';
import 'package:artavia/page/calendar/calendar_controller.dart';
import 'package:artavia/page/budget/budget_controller.dart';

/// Memperbarui semua data pada seluruh controller yang sedang aktif di memory.
/// Dipanggil setelah ada perubahan data (tambah/edit/hapus Transaksi, Rekening, atau Kategori).
void refreshAllGlobalData() {
  if (Get.isRegistered<HomeController>()) {
    Get.find<HomeController>().loadData();
  }
  if (Get.isRegistered<ReportController>()) {
    Get.find<ReportController>().loadData();
  }
  if (Get.isRegistered<ChartController>()) {
    Get.find<ChartController>().loadData();
  }
  if (Get.isRegistered<CalendarController>()) {
    final c = Get.find<CalendarController>();
    c.loadMonth(c.focusedDay.value);
    c.loadDayTransactions(c.selectedDay.value);
  }
  if (Get.isRegistered<BudgetController>()) {
    Get.find<BudgetController>().loadData();
  }
}
