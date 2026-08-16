import 'package:get/get.dart';
import 'package:artavia/page/transfer/transfer_controller.dart';

class TransferBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TransferController>(() => TransferController());
  }
}
