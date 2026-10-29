import 'package:get/get.dart';
import 'package:artavia/page/text_size/text_size_controller.dart';

class TextSizeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TextSizeController>(() => TextSizeController());
  }
}
