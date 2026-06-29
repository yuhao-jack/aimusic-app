import 'package:get/get.dart';
import 'package:aimusic_app/modules/profile/my_likes_controller.dart';

class MyLikesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyLikesController>(() => MyLikesController());
  }
}
