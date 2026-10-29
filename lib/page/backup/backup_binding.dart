import 'package:get/get.dart';
import 'package:artavia/page/backup/backup_controller.dart';

class BackupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BackupController>(() => BackupController());
  }
}
