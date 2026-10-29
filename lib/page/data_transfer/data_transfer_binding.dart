import 'package:get/get.dart';
import 'package:artavia/page/data_transfer/export_controller.dart';
import 'package:artavia/page/data_transfer/import_controller.dart';
import 'package:artavia/page/data_transfer/import_history_controller.dart';

/// Ekspor & impor share one binding: the import steps reuse the
/// ImportController created with the Ekspor & impor screen.
class DataTransferBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExportController>(() => ExportController());
    Get.lazyPut<ImportController>(() => ImportController());
  }
}

class ImportHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ImportHistoryController>(() => ImportHistoryController());
  }
}
