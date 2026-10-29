import 'package:get/get.dart';
import 'package:artavia/page/add_transaction/add_transaction_controller.dart';

class AddTransactionBinding extends Bindings {
  AddTransactionBinding({this.initialTab});

  final String? initialTab;

  @override
  void dependencies() {
    Get.lazyPut<AddTransactionController>(
        () => AddTransactionController(initialTab: initialTab));
  }
}
