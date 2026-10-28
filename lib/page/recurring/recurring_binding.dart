import 'package:get/get.dart';
import 'package:artavia/page/recurring/recurring_controller.dart';

class RecurringBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RecurringController>(() => RecurringController());
  }
}
