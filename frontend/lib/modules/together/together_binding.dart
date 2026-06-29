import 'package:get/get.dart';
import 'package:aimusic_app/modules/together/together_controller.dart';

class TogetherBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TogetherController());
  }
}
