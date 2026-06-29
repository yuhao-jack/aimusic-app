import 'package:get/get.dart';
import 'package:aimusic_app/modules/profile/my_works_controller.dart';

class MyWorksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyWorksController>(() => MyWorksController());
  }
}
