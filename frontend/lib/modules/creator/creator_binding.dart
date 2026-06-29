import 'package:get/get.dart';
import 'package:aimusic_app/modules/creator/creator_controller.dart';

class CreatorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreatorController>(() => CreatorController());
  }
}
