import 'package:get/get.dart';
import 'package:artavia/page/ledger/ledger_controller.dart';

class LedgerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LedgerController>(() => LedgerController());
  }
}
