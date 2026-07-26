import 'package:get/get.dart';
import 'package:artavia/page/home/home_controller.dart';
import 'package:artavia/page/chart/chart_controller.dart';
import 'package:artavia/page/report/report_controller.dart';
import 'package:artavia/page/profile/profile_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<ChartController>(() => ChartController());
    Get.lazyPut<ReportController>(() => ReportController());
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
