import 'package:get/get.dart';
import 'package:artavia/page/account_management/account_management_controller.dart';

class AccountManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AccountManagementController>(() => AccountManagementController());
  }
}
