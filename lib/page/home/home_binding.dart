import 'package:get/get.dart';
import 'package:artavia/page/home/home_controller.dart';
import 'package:artavia/page/account_management/account_management_controller.dart';
import 'package:artavia/page/report/report_controller.dart';
import 'package:artavia/page/settings/settings_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<AccountManagementController>(
        () => AccountManagementController(),
        fenix: true);
    Get.lazyPut<ReportController>(() => ReportController());
    Get.lazyPut<SettingsController>(() => SettingsController(), fenix: true);
  }
}
