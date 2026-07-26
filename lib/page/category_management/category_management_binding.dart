import 'package:get/get.dart';
import 'package:artavia/page/category_management/category_management_controller.dart';

class CategoryManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CategoryManagementController>(() => CategoryManagementController());
  }
}
